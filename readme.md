# Passwordless-DynamoStore

This module provides token storage for
[Passwordless](https://www.npmjs.com/package/passwordless), a module for
[Express](https://www.npmjs.com/package/express) that allows website
authentication without passwords, using verification through email or other
means. Visit the [Passwordless project's website](https://passwordless.net) for
more details.

Storage for this module is provided by [Amazon Web
Services'](https://aws.amazon.com/)
[DynamoDB](https://aws.amazon.com/dynamodb/). You will need an AWS account in
order to use this module.

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

### Test
```bash
$ npm test
```
