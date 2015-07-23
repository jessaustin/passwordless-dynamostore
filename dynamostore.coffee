# dynamostore
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license
#
# This module is a Passwordless Token Store based on AWS' DynamoDB. The
# constructor takes an optional options object, with three members. The
# "dynamoOptions" option is passed to the aws-sdk DynamoDB object constructor.
# The "tableParams" option is passed to the DynamoDB:createTable method. The
# stronglyConsistentAuth option defaults to false, and controls whether the
# authenticate method waits for strong consistency, or as is more typical in
# AWS settles for eventual consistency. If you have weird problems try changing
# this option first.

{pseudoRandomBytes} = require 'crypto'
{DynamoDB} = require 'aws-sdk'
bcrypt = require 'bcryptjs'
deepExtend = require 'deep-extend'
TokenStore = require 'passwordless-tokenstore'

module.exports = class DynamoStore extends TokenStore
  constructor: ({dynamoOptions, tableParams, stronglyConsistentAuth}={}) ->
    @db = new DynamoDB dynamoOptions ? {}
    @stronglyConsistentAuth = stronglyConsistentAuth ? no
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
    # most methods will wait on the table
    @table.then (tableName) =>
      # is this data safe at rest?
      bcrypt.hash token, 10, (err, hashedToken) =>
        if err then callback err else @db.putItem
          TableName: tableName
          Item:
            uid: S: uid
            dummy: N: '0'
            invalid: N: Date.now() + msToLive + ''
            hashedToken: S: hashedToken
            originUrl: S: originUrl if originUrl?
        , callback
    , callback

  authenticate: (token, uid, callback) ->
    throw new InvalidParams 'authenticate' unless token and uid and callback
    @table.then (tableName) =>
      @db.query
        TableName: tableName
        ConsistentRead: @stronglyConsistentAuth
        ExpressionAttributeValues:
          ':uid': S: uid
          ':now': N: Date.now() + ''
        IndexName: 'uid-invalid-index'
        KeyConditionExpression: 'uid = :uid and invalid > :now'
        ProjectionExpression: 'invalid, hashedToken, originUrl'
      , (err, data) ->
        if err
          callback err, no
        else if not data.Items.length
          callback null, no
        else
          bcrypt.compare token, data.Items[0]?.hashedToken?.S, (err, valid) ->
            if err
              callback err, no
            else if valid
              callback null, yes, data.Items[0].originUrl?.S
            else
              callback null, no
    , (err) ->
      callback err, no

  invalidateUser: (uid, callback) ->
    throw new InvalidParams 'invalidateUser' unless uid and callback
    @table.then (tableName) =>
      @db.deleteItem
        TableName: tableName
        Key:
          uid: S: uid
          dummy: N: '0'
      , callback
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

  # not a standard token store method, but useful during testing
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
        params = deepExtend {}, defaultParams, {TableName}, tableParams
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

# if you pass in wildly different overriding tableParams you will have problems
defaultParams =
  AttributeDefinitions: [
    AttributeType: 'S', AttributeName: 'uid'
  , AttributeType: 'N', AttributeName: 'dummy'
  , {AttributeType: 'N', AttributeName: 'invalid'}  # extra {} for cs bug
  ]
  KeySchema: [
    KeyType: 'HASH', AttributeName: 'uid'
  , KeyType: 'RANGE', AttributeName: 'dummy'
  ]
  LocalSecondaryIndexes: [                          # need local 2I to allow
    IndexName: 'uid-invalid-index',                 # ConsistentRead
    KeySchema: [
      KeyType: 'HASH',  AttributeName: 'uid'
    , KeyType: 'RANGE', AttributeName: 'invalid'    # need range attr to allow
    ]                                               # *local* 2I
    Projection: ProjectionType: 'ALL'
  ]
  ProvisionedThroughput:                            # these can be increased
    ReadCapacityUnits:  1
    WriteCapacityUnits: 1
