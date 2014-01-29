aws = require 'aws-lib'

conf = require '../conf'
winston = require('./winstonWrapper').winston
sesUtils = require './sesUtils'
eventDigestHelpers = require './eventDigestHelpers'
emailUtils = this


exports.sendEventDigestEmail = ( eventDigest, user, callback ) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return
  unless user then callback winston.makeMissingParamError 'user'; return
  unless user.email then callback winston.makeMissingParamError 'user.email'; return

  eventDigestHelpers.getEventDigestEmailText eventDigest, user, (error, emailText) ->
    if error then callback error; return

    recipients = [user.email]
    sender = conf.sendingEmailAddress
    text = emailText
    html = ''
    subject = 'Your daily RealDart'

    winston.doInfo 'about to send email...',
      recipients: recipients
      sender: sender
      text: text
      subject: subject

    #TEMP
    #callback winston.makeError 'temp error!'
    
    sesUtils.sendEmail recipients, sender, text, html, subject, callback