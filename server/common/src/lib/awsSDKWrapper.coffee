AWS = require 'aws-sdk'

conf = require '../conf'

awsConf = conf.aws

AWS.config.update
  accessKeyId: awsConf.key
  secretAccessKey: awsConf.secret
  region: awsConf.region

exports.AWS = AWS