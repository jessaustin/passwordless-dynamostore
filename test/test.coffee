# test.coffee
#
# copyright (c) Jess Austin <jess.austin@gmail.com>, MIT license

standardTests = require 'passwordless-tokenstore-test'
DynamoStore = require '../dynamostore'

ds = null

standardTests ->
  ds = new DynamoStore
    dynamoOptions: region: 'us-west-2'
    stronglyConsistentAuth: yes
, (done) ->
  done()
, (done) ->
  ds.dropTable()    # avoid littering AWS with lots of tables
  done()
, 2000  # need this for the "flow" section
