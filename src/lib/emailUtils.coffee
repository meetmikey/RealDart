aws = require 'aws-lib'

conf = require '../conf'
winston = require('./winstonWrapper').winston
sesUtils = require './sesUtils'
eventDigestHelpers = require './eventDigestHelpers'
emailUtils = this


exports.sendEventDigestEmail = ( eventDigest, user, callback ) ->

  eventDigestHelpers.getEventDigestEmailText eventDigest, user, (error, emailText) ->
    if error then callback error; return

    recipients = [user.email]
    sender = conf.sendingEmailAddress
    text = emailText
    html = text
    subject = 'Your daily RealDart'

    sesUtils.sendEmail recipients, sender, text, html, subject, callback