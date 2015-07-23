# test.coffee
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license

standardTests = require 'passwordless-tokenstore-test'
DynamoStore = require '../dynamostore'

ds = null

factory = ->
  ds = new DynamoStore
    dynamoOptions: region: 'us-west-2'
  ds

before = (done) ->
  console.log ds

after = (done) ->
  ds.clear (err) ->
    if err then done err else done()

standardTests factory,
  (done) -> done()
  after
  50000
