# test.coffee
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license

standardTests = require 'passwordless-tokenstore-test'
DynamoStore = require '../dynamostore'

ds = null

factory = ->
  ds = new DynamoStore
    dynamoOptions: region: 'us-west-2'

standardTests factory,
  (done) ->
    done()
  (done) ->
    ds.dropTable()
    done()
  50000
