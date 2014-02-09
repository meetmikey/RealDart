aws = require 'aws-lib'

conf = require '../conf'
winston = require('./winstonWrapper').winston

sesUtils = this

exports._init = () ->
  sesUtils._client = aws.createSESClient conf.aws.key, conf.aws.secret

exports.sendEmail = (recipients, sender, text, html, subject, callback) ->
  sendArgs =
    'Message.Body.Text.Charset': 'UTF-8'
    'Message.Body.Text.Data': text
    'Message.Subject.Charset': 'UTF-8'
    'Message.Subject.Data': subject
    'Source': sender

  n = 1
  recipients.forEach (rec) ->
    sendArgs['Destination.ToAddresses.member.' + n] = rec
    n += 1

  if html
    sendArgs['Message.Body.Html.Data'] = html
    sendArgs['Message.Body.Html.Charset'] = 'UTF-8'

  sesUtils._client.call 'SendEmail', sendArgs, (sesError, result) ->
    if sesError
      callback winston.makeError 'sesError: ' + sesError
    else
      callback()

exports.sendInternalNotificationEmail = (text, subject, callback) ->
  sesUtils.sendEmail [conf.email.itAddress], conf.email.noReplyAddress, text, text, subject + ' on ' + os.hostname(), callback

sesUtils._init()