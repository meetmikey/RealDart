Imap = require 'imap'
xoauth2 = require 'xoauth2'

winston = require('./winstonWrapper').winston

conf = require '../conf'
constants = require '../constants'

imapConnect = this

exports.createImapConnection = (email, accessToken, callback) ->
  unless email then winston.doMissingParamError 'email'; return null
  unless accessToken then winston.doMissingParamError 'accessToken'; return null

  xoauthParams = imapConnect.getXOauthParams email, accessToken
  xoauth2gen = xoauth2.createXOAuth2Generator xoauthParams

  xoauth2gen.getToken (err, xoauth2Token) ->
    if err
      callback winston.makeError 'xoauth2gen error',
        err: err
      return

    imapParams = conf.gmailImapParams
    imapParams.user = email
    imapParams.xoauth2 = xoauth2Token

    winston.doInfo 'imapParams',
      imapParams: imapParams

    imapConnection = new Imap imapParams
    callback null, imapConnection

exports.getXOauthParams = (email, accessToken) ->
  xoauthParams =
    user: email
    clientId: conf.auth.google.clientId
    clientSecret: conf.auth.google.clientSecret
    accessToken : accessToken
    #refreshToken: refreshToken

  xoauthParams

exports.openSentMailBox = (imapConnection, email, callback) ->
  unless imapConnection then winston.doMissingParamError 'imapConnection'; return null
  unless email then winston.doMissingParamError 'email'; return null

  callbackCalled = false
  callbackWrapper = (error, sentMailBox) ->
    if callbackCalled
      winston.doWarn 'imapConnect.openSentMailBox double callback'
      if error
        winston.handleError error
    else
      callbackCalled = true
      callback error, sentMailBox

  imapConnection.connect()
  imapConnection.once 'ready', (err) ->
    if err
      imapConnect.handleOpenSentMailBoxReadyError err, email, callbackWrapper
    else
      imapConnect.handleOpenSentMailBoxReady imapConnection, email, callbackWrapper

  imapConnection.once 'error', (err) ->
    imapConnect.handleOpenSentMailBoxError err, email, callbackWrapper

  imapConnection.once 'end', ->
    winston.doInfo 'Connection ended for user',
      email: email

  imapConnection.on 'alert', (msg) ->
    winston.doWarn 'Imap alert',
      msg: msg
      email: email
      

exports.handleOpenSentMailBoxReady = (imapConnection, email, callback) ->
  unless imapConnection then winston.doMissingParamError 'imapConnection'; return null
  unless email then winston.doMissingParamError 'email'; return null

  # check whether they are "Google Mail" or "GMail"
  imapConnection.getBoxes '', (getBoxesErr, boxes) ->
    if getBoxesErr then callback winston.makeError 'Could not get boxes', {err: getBoxesErr}; return
    unless boxes then callback winston.makeError 'No mailBoxes found'; return

    imapConnect.findSentMailBox boxes, (error, fullSentMailBoxName, folderNames) ->
      if error then callback error; return
      unless fullSentMailBoxName then callback winston.makeError 'no fullSentMailBoxName, but no error!'; return

      imapConnection.openBox fullSentMailBoxName, true, (openBoxErr, sentMailBox) ->
        if openBoxErr
          callback winston.makeError 'Could not open sentMailBox',
            err: openBoxErr
          return

        unless sentMailBox
          callback winston.makeError 'no sentMailBox', {email: email}; return

        # add dictionary of relevant folders to the sentMailBox
        sentMailBox.folderNames = folderNames
        callback null, sentMailBox


exports.findSentMailBox = (boxes, callback) ->

  boxToOpen = undefined
  hasGmail = false
  hasGoogleMail = false

  keys = Object.keys boxes
  keys.forEach (boxName) ->
    if boxName is '[Gmail]'
      if boxes[boxName].children
        boxToOpen = boxName
        hasGmail = true
    if boxName is '[Google Mail]'
      if boxes[boxName].children
        boxToOpen = boxName
        hasGoogleMail = true

  unless boxToOpen
    winstonError = winston.makeError 'Could not find candidate mailBox to open',
      boxes: boxes
    winston.setErrorType winstonError, constants.errorType.imap.NO_BOX_TO_OPEN
    callback winstonError
    return

  sentMailBox = undefined
  folderNames = {}

  # corner case - both Gmail and Google Mail folders are present
  if hasGmail and hasGoogleMail
    childrenGmail = boxes['[Gmail]'].children
    for key of childrenGmail
      childrenGmail[key].attribs.forEach (attrib) ->
        if attrib is 'SENTMAIL' or attrib is "\\Sent"
          sentMailBox = key
          boxToOpen = '[Gmail]'
        folderNames[attrib] = key

    childrenGoogleMail = boxes["[Google Mail]"].children
    for key of childrenGoogleMail
      childrenGoogleMail[key].attribs.forEach (attrib) ->
        if attrib is 'SENTMAIL' or attrib is "\\Sent"
          sentMailBox = key
          boxToOpen = '[Google Mail]'
        folderNames[attrib] = key

  else
    children = boxes[boxToOpen].children
    if children
      for key of children
        children[key].attribs.forEach (attrib) ->
          folderNames[attrib] = key
          if attrib is 'SENTMAIL' or attrib is "\\Sent"
            sentMailBox = key  

  unless sentMailBox
    winstonError = winston.makeError 'Error: Could not find SENTMAIL folder',
      folderNames: folderNames
    winston.setErrorType winstonError, constants.errorType.imap.SENT_MAIL_DOESNT_EXIST
    callback winstonError
    return

  fullBoxName = boxToOpen + '/' + sentMailBox
  winston.doInfo 'Successfully connected to imap, now opening mailBox',
    fullBoxName: fullBoxName

  callback null, fullBoxName, folderNames


exports.handleOpenSentMailBoxError = (err, email, callback) ->
  unless err then callback()

  winstonError = winston.makeError 'imap connect error',
    err: err
    email: email

  if err.message and err.message.indexOf('IMAP access is disabled for your domain') isnt -1
    winston.doWarn 'imap access disabled for domain'
    winston.setErrorType winstonError, constants.errorType.imap.DOMAIN_ERROR

  else if err.level
    winston.setErrorType winstonError, err.level

  else if err.source
    winston.setErrorType winstonError, err.source
    if err.source is 'timeout'
      winston.setSuppressErrorFlag winstonError, true
      winston.doWarn 'imap connect error timeout',
        err: err
        email: email

  callback winstonError

exports.handleOpenSentMailBoxReadyError = (err, email, callback ) ->
  winstonError = winston.makeError 'imap connect error',
    err: err
    email: email

  if err and err.level
    winston.setErrorType winstonError, err.level

  else if err and err.source
    winston.setErrorType winstonError, err.source

  if err.source is 'timeout'
    winston.setSuppressErrorFlag winstonError, true
    winston.doWarn 'imap connect error timeout',
      err: err
      email: email

  if callback
    callback winstonError

exports.closeMailBox = (imapConnection, callback) ->
  imapConnection.closeBox callback

exports.logout = (imapConnection, callback) ->
  winston.doInfo 'imapConnect.logout: logging out'
  imapConnection.end()
  callback()