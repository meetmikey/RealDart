aws = require 'aws-lib'

conf = require '../conf'
winston = require('./winstonWrapper').winston

sesUtils = this

sesClient = aws.createSESClient conf.aws.ses.key, conf.aws.ses.secret

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

  sesClient.call 'SendEmail', sendArgs, (sesError, result) ->
    if err
      callback winston.makeError 'sesError',
        sesError: sesError
    else
      callback()