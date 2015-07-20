{DynamoDB} = require 'aws-sdk'
bcrypt = require 'bcryptjs'
extend = require 'deep-extend'
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
          resolve "passwordless-dynamostore-table-#{
            bytes.toString 'base64'
              .replace /[^a-zA-Z0-9_.-]/g, ''}"
    .then (TableName) =>
      @table = TableName
      # XXX maybe not if table exists?
      params = extend {}, defaultParams, {TableName}, tableParams
      @db.createTable params, (err) ->
        # every @ready.then must handle this
        throw "couldn't create table" if err

  authenticate: (token, uid, callback) ->
    unless token and uid and callback
      throw new InvalidParams 'authenticate'
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
          callback err, no, null
        else
          [..., recent] = data.Items
          bcrypt.compare token, recent.hashedToken?.S, (err, valid) ->
            if err
              callback err, no, null
            else if valid
              callback null, yes, recent.originUrl.S
            else
              callback null, no, null
    , (err) ->
      callback err, no, null

  storeOrUpdate: (token, uid, msToLive, originUrl, callback) ->
    unless token and uid and msToLive and callback
      throw new InvalidParams 'storeOrUpdate'
    @ready.then =>
      bcrypt.hash token, 10, (err, hashedToken) =>
        callback err if err
        @db.putItem
          TableName: @table
          Item:
            uid: S: uid
            invalid: N: Date.now() + msToLive + ''
            hashedToken: S: hashedToken
            originUrl: S: originUrl if originUrl
        , (err) ->
          callback err if err
          callback()
    , (err) ->
      callback err

  invalidateUser: (uid, callback) ->
    unless uid and callback
      throw new InvalidParams 'invalidateUser'
    @ready.then =>
#      @db.
#        TableName: @table
#      , callback

  clear: (callback) ->
    unless callback
      throw new InvalidParams 'clear'

  length: (callback) ->
    unless callback
      throw new InvalidParams 'length'
    @ready.then =>
      @db.scan
        TableName: @table
        Select: 'COUNT'
        ScanFilter:
          invalid:
            ComparisonOperator: 'GT'
            AttributeValueList: [N: Date.now() + '']
      , (err, data) ->
        callback err if err
        callback null, data.Count
    , (err) ->
      callback err

# passwordless-tokenstore should call bcrypt directly, not us?

class DynamoError extends Error
  class: DynamoStore

class InvalidParams extends DynamoError
  constructor: (method) ->
    @message = "#{@class}:#{method} called with invalid parameters"

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
