winston = require('./winstonWrapper').winston
imapConnect = require './imapConnect'

conf = require '../conf'

imapHelpers = this

exports.getHeaders = (userId, imapConnection, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return
  unless ( minUID is 0 ) or ( minUID > 0 )  then callback winston.makeMissingParamError 'minUID'; return
  unless ( maxUID is 0 ) or ( maxUID > 0 )  then callback winston.makeMissingParamError 'maxUID'; return
  unless ( minUID <= maxUID ) then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return

  winston.doInfo 'getHeaders',
    minUid: minUid
    maxUid: maxUid

  hasCalledBack = false
  callbackWrapper = (error, headers) ->
    if hasCalledBack
      winston.doWarn 'imapHelpers.getHeaders double callback'
    else
      callback error, headers
      hasCalledBack = true

  uidQuery = minUid + ':' + maxUid
  headerFields = 'HEADER.FIELDS (' + conf.gmail.headerFieldsToFetch.join(' ') + ')'
  imapFetch = imapConn.fetch uidQuery,
    bodies: headerFields
  
  headers = []
  
  imapFetch.on 'message', (msg, uid) ->

    mailInfo = {}

    msg.on 'body', (stream, info) ->
      buffer = ''
      count = 0
      stream.on 'data', (chunk) ->
        count += chunk.length
        buffer += chunk.toString 'utf8'

      stream.once 'end', ->

        winston.doInfo 'stream end',
          which: info?.which

        unless info.which is headerFields
          return

        emailHeaders = Imap.parseHeader buffer
        mailInfo['messageId'] = emailHeaders['message-id']

        mailObject['recipients'] = mailUtils.getAllRecipients emailHeaders

    msg.once 'attributes', (attrs) ->
      mailInfo['uid'] = attrs.uid
      if attrs['date']
        mailInfo['date'] = new Date( Date.parse( attrs['date'] ) )

    msg.once 'end', ->
      docsToSave.push mailObject
      
      unless mailObject.gmDate
        winston.doWarn "mailObject does not have a gmDate",
          mailObject: mailObject

  imapFetch.on 'end', ->
    winston.doInfo 'fetch end',
      minUid: minUid
      maxUid: maxUid

    callbackWrapper null, headers

    
  imapFetch.on 'error', (err) ->
    callbackWrapper winston.makeError 'imap fetch error',
      message: err?.message
      stack: err?.stack