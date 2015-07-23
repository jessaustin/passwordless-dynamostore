# Passwordless-DynamoStore

[![Dependency Status][david-img]][david-url]
[![devDependency Status][david-dep-img]][david-dep-url]
[![NPM][npmjs-img]][npmjs-url]

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

| Property                 | Explanation                            |
| -------------------------|----------------------------------------|
| `dynamoOptions`          | passed to [constructor][const]         |
| `tableParams`            | passed to [createTable method][create] |
| `stronglyConsistentAuth` | will the [`authenticate`][auth] method use strong consistency? [default: `false`, i.e. *eventual* consistency]  |

### Test
```bash
$ npm test
```

[travis-url]: //travis-ci.org/jessaustin/passwordless-dynamostore "Travis"
[travis-img]: //travis-ci.org/jessaustin/passwordless-dynamostore.svg?branch=master
[cover-url]: //coveralls.io/r/jessaustin/passwordless-dynamostore?branch=master "Coveralls"
[cover-img]: //coveralls.io/repos/jessaustin/passwordless-dynamostore/badge.svg?branch=master
[david-url]: //david-dm.org/jessaustin/passwordless-dynamostore "David"
[david-img]: //david-dm.org/jessaustin/passwordless-dynamostore.svg "x"
[david-dep-url]: //david-dm.org/jessaustin/passwordless-dynamostore#info=devDependencies "David for dev"
[david-dep-img]: //david-dm.org/jessaustin/passwordless-dynamostore/dev-status.svg
[npmjs-url]: //www.npmjs.org/package/passwordless-dynamostore "npm Registry"
[npmjs-img]: //nodei.co/npm/passwordless-dynamostore.png?compact=true
[const]: //docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#constructor-property "AWS.DynamoDB"
[create]: //docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#createTable-property "AWS.DynamoDB.createTable()" 
[auth]: //github.com/florianheinemann/passwordless-tokenstore/blob/master/lib/tokenstore.js#L7-L22 "TokenStore.authenticate()"
