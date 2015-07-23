# dynamostore
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license

{pseudoRandomBytes} = require 'crypto'
{DynamoDB} = require 'aws-sdk'
bcrypt = require 'bcryptjs'
extend = require 'deep-extend'
TokenStore = require 'passwordless-tokenstore'

module.exports = class DynamoStore extends TokenStore
  constructor: ({dynamoOptions, tableParams, consistentRead}={}) ->
    @db = new DynamoDB dynamoOptions ? {}
    @consistent = consistentRead ? no
    # use promises so constructor is sync; other methods async anyway
    @table = new Promise (resolve, reject) =>
      TableName = tableParams?.TableName
      if TableName?
        @db.describeTable {TableName}, (err) ->
          if err then delete tableParams.TableName else resolve TableName
      newTable @db, tableParams
        .then resolve, reject

  storeOrUpdate: (token, uid, msToLive, originUrl, callback) ->
    unless token and uid and msToLive and callback
      throw new InvalidParams 'storeOrUpdate'
    @table.then (tableName) =>
      bcrypt.hash token, 10, (err, hashedToken) =>
        if err then callback err else @db.putItem
          TableName: tableName
          Item:
            uid: S: uid
            dummy: N: '0'
            invalid: N: Date.now() + msToLive + ''
            hashedToken: S: hashedToken
            originUrl: (S: originUrl) if originUrl
        , (err) =>
          if err then callback err else @db.query
            TableName: tableName
            Select: 'COUNT'
            ConsistentRead: yes
            ExpressionAttributeValues:
              ':uid': S: uid
              ':dummy': N: '0'
            KeyConditionExpression: 'uid = :uid and dummy = :dummy'
          , callback
    , callback

  authenticate: (token, uid, callback) ->
    throw new InvalidParams 'authenticate' unless token and uid and callback
    @table.then (tableName) =>
      @db.query
        TableName: tableName
        ConsistentRead: yes
        ExpressionAttributeValues:
          ':uid': S: uid
          ':now': N: Date.now() + ''
        IndexName: 'uid-invalid-index'
        KeyConditionExpression: 'uid = :uid and invalid > :now'
        ProjectionExpression: 'invalid, hashedToken, originUrl'
      , (err, data) ->
        if err
          callback err, no, null
        else if not data.Items.length
          callback null, no, null
        else
          bcrypt.compare token, data.Items[0]?.hashedToken?.S, (err, valid) ->
            if err
              callback err, no, null
            else if valid
              callback null, yes, data.Items[0].originUrl?.S
            else
              callback null, no, null
    , (err) ->
      callback err, no, null

  invalidateUser: (uid, callback) ->
    throw new InvalidParams 'invalidateUser' unless uid and callback
    @table.then (tableName) =>
      @db.deleteItem
        TableName: tableName
        Key:
          uid: S: uid
          dummy: N: '0'
      , (err, data) =>
        if err then callback err else @db.query
          TableName: tableName
          Select: 'COUNT'
          ConsistentRead: yes
          ExpressionAttributeValues:
            ':uid': S: uid
            ':dummy': N: '0'
          KeyConditionExpression: 'uid = :uid and dummy = :dummy'
        , ->
          callback()
    , callback

  clear: (callback) ->
    throw new InvalidParams 'clear' unless callback
    @table = newTable @db, {}
    @table.then =>
      @dropTable()
      callback()      # no need to wait on dropTable()
    , callback

  length: (callback) ->
    throw new InvalidParams 'length' unless callback
    @table.then (tableName) =>
      @db.scan
        TableName: tableName
        Select: 'COUNT'
      , (err, data) ->
        if err then callback err else callback null, data.Count
    , callback

  dropTable: ->
    @table.then (tableName) =>
      @db.deleteTable
        TableName: tableName
      , ->
    , ->

# returns a promise; all methods should .then() to be sure there is a table
newTable = (db, tableParams) ->
  new Promise (resolve, reject) =>
    pseudoRandomBytes 6, (err, bytes) =>
      if err
        reject "couldn't get random bytes"
      else
        TableName = "passwordless-dynamostore-#{bytes.toString 'base64'
          .replace /[^a-zA-Z0-9_.-]/g, ''}"
        params = extend {}, defaultParams, {TableName}, tableParams
        db.createTable params, (err) =>
          if err
            reject "couldn't create table #{TableName}, #{err}"
          else
            waitOnTableCreation db, TableName, resolve, reject

# everything has to wait on table creation; ConsistentRead doesn't help
waitOnTableCreation = (db, name, resolve, reject) ->
  db.describeTable TableName: name, (err, data) ->
    if err
      reject err
    else if data?.Table?.TableStatus is 'ACTIVE'
      resolve name
    else
      waitOnTableCreation db, name, resolve, reject        # otherwise, recurse

class DynamoError extends Error
  targetClass: DynamoStore

class InvalidParams extends DynamoError
  constructor: (method) ->
    @message = "#{@targetClass}:#{method} called with invalid parameters"

class AwsParams extends DynamoError
  constructor: () ->

defaultParams =
  AttributeDefinitions: [
    AttributeType: 'S', AttributeName: 'uid'
  , AttributeType: 'N', AttributeName: 'dummy'
  , {AttributeType: 'N', AttributeName: 'invalid'}
  ]
  KeySchema: [
    KeyType: 'HASH', AttributeName: 'uid'
  , KeyType: 'RANGE', AttributeName: 'dummy'
  ]
  LocalSecondaryIndexes: [
    IndexName: 'uid-invalid-index',
    KeySchema: [
      KeyType: 'HASH',  AttributeName: 'uid'
    , KeyType: 'RANGE', AttributeName: 'invalid'
    ]
    Projection: ProjectionType: 'ALL'
  ]
  ProvisionedThroughput:
    ReadCapacityUnits:  1
    WriteCapacityUnits: 1
