AWS = require('./awsSDKWrapper').AWS
winston = require('./winstonWrapper').winston

conf = require '../conf'

sesUtils = this


exports._init = () ->
  sesUtils._initAWS()


exports._initAWS = () ->
  sesUtils._ses = new AWS.SES
    apiVersion: conf.aws.ses.apiVersion


exports.sendEmail = (recipients, sender, text, html, subject, callback) ->
  charSet = conf.aws.ses.charSet
  emailParams =
    Destination:
      ToAddresses: recipients
    Message:
      Body:
        Html:
          Data: html
          Charset: charSet
        Text:
          Data: test
          Charset: charSet
      Subject:
        Data: subject
        Charset: charSet
    Source: sender

  sesUtils._ses.sendEmail emailParams, (sesError, result) ->
    if sesError
      callback winston.makeError 'sesError: ' + sesError
    else
      callback()


exports.sendInternalNotificationEmail = (text, subject, callback) ->
  sesUtils.sendEmail [conf.email.itAddress], conf.email.noReplyAddress, text, text, subject + ' on ' + os.hostname(), callback

sesUtils._init()