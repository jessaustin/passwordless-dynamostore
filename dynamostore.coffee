# dynamostore
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license

{DynamoDB} = require 'aws-sdk'
bcrypt     = require 'bcryptjs'
extend     = require 'deep-extend'
TokenStore = require 'passwordless-tokenstore'

module.exports = class DynamoStore extends TokenStore
  # use promises so constructor is synch; other methods async anyway
  constructor: ({dynamoOptions, tableParams}={}) ->
    @db = new DynamoDB dynamoOptions ? {}
    @ready = new Promise (resolve, reject) ->
      if tableParams?.TableName?
        resolve tableParams.TableName
      else
        crypto.pseudoRandomBytes 6, (err, bytes) ->
          reject "couldn't get random bytes" if err
          resolve "passwordless-dynamostore-#{bytes.toString 'base64'
            .replace /[^a-zA-Z0-9_.-]/g, ''}"
    .then (TableName) =>
      @table = TableName
      # XXX maybe not if table exists?
      params = extend {}, defaultParams, {TableName}, tableParams
      @db.createTable params, (err) ->
        # every @ready.then must handle this
        throw "couldn't create table #{TableName}" if err

  storeOrUpdate: (token, uid, msToLive, originUrl, callback) ->
    unless token and uid and msToLive and callback
      throw new InvalidParams 'storeOrUpdate'
    # XXX invalidate previous entries for uid?
    @ready.then =>
      bcrypt.hash token, 10, (err, hashedToken) =>
        if err then callback err else @db.putItem
          TableName: @table
          Item:
            uid: S: uid
            invalid: N: Date.now() + msToLive + ''
            hashedToken: S: hashedToken
            originUrl: (S: originUrl) if originUrl
        , callback
    , callback

  authenticate: (token, uid, callback) ->
    throw new InvalidParams 'authenticate' unless token and uid and callback
    @ready.then =>
      @db.query
        TableName: @table
        ExpressionAttributeValues:
          ':uid': S: uid
          ':now': N: Date.now() + ''
        KeyConditionExpression: 'uid = :uid and invalid > :now'
        ProjectionExpression: 'invalid, hashedToken, originUrl'
      , (err, data) ->
        if err
          callback err, no
        else
          # longest-lived should be the most recent; use that
          [..., recent] = data.Items
          bcrypt.compare token, recent?.hashedToken?.S, (err, valid) ->
            if err
              callback err, no
            else if valid
              callback null, yes, recent.originUrl?.S
            else
              callback null, no
    , (err) ->
      callback err, no

  invalidateUser: (uid, callback) ->
    throw new InvalidParams 'invalidateUser' unless uid and callback
    @ready.then =>
      @db.query
        TableName: @table
        ExpressionAttributeValues: ':uid': S: uid
        KeyConditionExpression: 'uid = :uid'
        ProjectionExpression: 'invalid, hashedToken, originUrl'
      , (err, data) =>
        if err then callback err else promises = (for item in data.Items
          new Promise (resolve, reject) =>
            @db.deleteItem
              TableName: @table
              Key:
                uid: S: uid
                invalid: item.invalid
            , (err, data) ->
              if err then reject err else resolve())
        Promise.all promises
          .then callback
    , callback

  clear: (callback) ->
    throw new InvalidParams 'clear' unless callback
    @ready.then =>
      now = Date.now() + ''
      @db.scan
        TableName: @table
        ProjectionExpression: 'uid, invalid'
        ExpressionAttributeValues: ':now': N: now
        FilterExpression: 'invalid > :now'
      , (err, data) =>
        if err then callback err else promises = (for item in data.Items
          new Promise (resolve, reject) =>
            @db.deleteItem
              TableName: @table
              Key:
                uid: item.uid
                invalid: item.invalid
            , (err) ->
              if err then reject err else resolve())
        Promise.all promises
          .then callback
    , callback

  length: (callback) ->
    throw new InvalidParams 'length' unless callback
    @ready.then =>
      @db.scan
        TableName: @table
        Select: 'COUNT'
      , (err, data) ->
        if err then callback err else callback null, data.Count
    , callback

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
  , AttributeType: 'N', AttributeName: 'invalid'
  ]
  KeySchema: [
    KeyType: 'HASH', AttributeName: 'uid'
  , KeyType: 'RANGE', AttributeName: 'invalid'
  ]
  ProvisionedThroughput:
    ReadCapacityUnits: 1
    WriteCapacityUnits: 1
