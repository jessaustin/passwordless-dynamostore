# Passwordless-DynamoStore

[![NPM][npmjs-img]][npmjs-url]
[![Build Status][travis-img]][travis-url]
[![Coverage Status][cover-img]][cover-url]
[![Dependency Status][david-img]][david-url]
[![devDependency Status][david-dep-img]][david-dep-url]

This module provides token storage for
[Passwordless](//www.npmjs.com/package/passwordless), a module for
[Express](//www.npmjs.com/package/express) that allows website
authentication without passwords, using verification through email or other
means. Visit the [Passwordless project's website](//passwordless.net) for
more details.

Storage for this module is provided by [Amazon Web Services'](
//aws.amazon.com/) [DynamoDB](//aws.amazon.com/dynamodb/). You will need an AWS
account in order to use this module.

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
This code assumes you have the AWS credentials [`aws_access_key_id` and
`aws_secret_access_key`][creds] defined in your environment.

An options object may be passed to the class constructor. There are three
relevant properties:

| Property                 | Explanation                              |
| -------------------------|------------------------------------------|
| `dynamoOptions`          | passed to [constructor][const]           |
| `tableParams`            | passed to [`createTable`][create] method |
| `stronglyConsistentAuth` | will the [`authenticate`][auth] method use strong consistency? [default: `false`, i.e. *eventual* consistency]  |

### Test
```bash
$ cd node_modules/passwordless-dynamostore/
$ npm install
$ npm test
```
**passwordless-dynamostore** is distributed under the [MIT
license](http://opensource.org/licenses/MIT).

[travis-url]: //travis-ci.org/jessaustin/passwordless-dynamostore "Travis"
[travis-img]: https://travis-ci.org/jessaustin/passwordless-dynamostore.svg?branch=master
[cover-url]: //coveralls.io/r/jessaustin/passwordless-dynamostore?branch=master "Coveralls"
[cover-img]: https://coveralls.io/repos/jessaustin/passwordless-dynamostore/badge.svg?branch=master&service=github
[david-url]: //david-dm.org/jessaustin/passwordless-dynamostore "David"
[david-img]: https://david-dm.org/jessaustin/passwordless-dynamostore.svg
[david-dep-url]: //david-dm.org/jessaustin/passwordless-dynamostore#info=devDependencies "David for dev"
[david-dep-img]: https://david-dm.org/jessaustin/passwordless-dynamostore/dev-status.svg
[npmjs-url]: //www.npmjs.org/package/passwordless-dynamostore "npm Registry"
[npmjs-img]: https://badge.fury.io/js/passwordless-dynamostore.svg
[creds]: //docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files "AWS Credentials"
[const]: //docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#constructor-property "AWS.DynamoDB()"
[create]: //docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#createTable-property "AWS.DynamoDB.createTable()" 
[auth]: //github.com/florianheinemann/passwordless-tokenstore/blob/master/lib/tokenstore.js#L7-L22 "TokenStore.authenticate()"
