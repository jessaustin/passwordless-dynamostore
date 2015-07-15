bcrypt = require 'bcryptjs'
Aws = require 'aws-sdk'
TokenStore = require 'passwordless-tokenstore'

module.exports = DynamoStore

class DynamoStore extends TokenStore
  constructor: (options={}) ->

  authenticate: (token, uid, callback) ->
    unless token and uid and callback
      throw new Error 'TokenStore:authenticate called with invalid parameters'

  storeOrUpdate: (token, uid, msToLive, originUrl, callback) ->

  invalidateUser: (uid, callback) ->

  clear: (callback) ->

  length: (callback) ->

validate = (token, storedItem, callback) ->
