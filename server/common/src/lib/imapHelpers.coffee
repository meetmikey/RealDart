imap = require 'imap'
_ = require 'underscore'

winston = require('./winstonWrapper').winston
imapConnect = require './imapConnect'
mailUtils = require './mailUtils'

conf = require '../conf'

imapHelpers = this

exports.getHeaders = (userId, imapConnection, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return
  unless minUID > 0 then callback winston.makeMissingParamError 'minUID'; return
  unless maxUID > 0 then callback winston.makeMissingParamError 'maxUID'; return
  unless minUID <= maxUID then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return

  hasCalledBack = false
  callbackWrapper = (error, headers) ->
    if hasCalledBack
      winston.doWarn 'imapHelpers.getHeaders double callback'
    else
      callback error, headers
      hasCalledBack = true

  uidQuery = minUID + ':' + maxUID
  headerFields = 'HEADER.FIELDS (' + conf.gmail.headerFieldsToFetch.join(' ') + ')'

  imapFetch = imapConnection.fetch uidQuery,
    bodies: headerFields
  
  headersArray = []
  
  imapFetch.on 'message', (msg, uid) ->

    mailInfo = {}
    msg.on 'body', (stream, info) ->
      buffer = ''
      stream.on 'data', (chunk) ->
        buffer += chunk.toString 'utf8'

      stream.once 'end', ->
        unless info.which is headerFields
          return

        emailHeaders = imap.parseHeader buffer
        mailInfo['messageId'] = emailHeaders['message-id']
        mailInfo['subject'] = emailHeaders['subject']
        mailInfo['recipientEmails'] = _.pluck mailUtils.getAllRecipients( emailHeaders ), 'email'

    msg.once 'attributes', (attrs) ->
      mailInfo['uid'] = attrs.uid
      if attrs['date']
        mailInfo['date'] = new Date( Date.parse( attrs['date'] ) )

    msg.once 'end', ->
      headersArray.push mailInfo

  imapFetch.on 'end', ->
    callbackWrapper null, headersArray
    
  imapFetch.on 'error', (err) ->
    callbackWrapper winston.makeError 'imap fetch error',
      message: err?.message
      stack: err?.stack