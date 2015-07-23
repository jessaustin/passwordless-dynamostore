# Passwordless-DynamoStore

This module provides token storage for
[Passwordless](//www.npmjs.com/package/passwordless), a module for
[Express](//www.npmjs.com/package/express) that allows website
authentication without passwords, using verification through email or other
means. Visit the [Passwordless project's website](//passwordless.net) for
more details.

Storage for this module is provided by [Amazon Web
Services'](//aws.amazon.com/) [DynamoDB](aws.amazon.com/dynamodb/). You will
need an AWS account in order to use this module.

### Install
```bash
$ npm install passwordless-dynamostore
```

### Use
Just like any other token store:
```javascript
var passwordless = require('passwordless');
var DynamoStore = require('passwordless-dynamostore');

passwordless.init(new DynamoStore({dynamoOptions: {region: 'eu-west-1'}}));
```

An options object may be passed to the class constructor. There are three
relevant properties:

Property               | Explanation
---------------------------------------------------------------------------------------------------------------------------------------------
dynamoOptions          | passed to [constructor](//docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#constructor-property)
tableParams            | passed to [createTable method](//docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#createTable-property)
stronglyConsistentAuth | will the `authenticate` method use strong consistency? [default: *eventual* consistency]

### Test
```bash
$ npm test
```

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
