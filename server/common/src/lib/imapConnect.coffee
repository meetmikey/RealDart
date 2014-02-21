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

    imapParams = conf.gmail.imapParams
    imapParams.user = email
    imapParams.xoauth2 = xoauth2Token

    imapConnection = new Imap imapParams
    imapConnection.email = email
    callback null, imapConnection

exports.getXOauthParams = (email, accessToken) ->
  xoauthParams =
    user: email
    clientId: conf.auth.google.clientId
    clientSecret: conf.auth.google.clientSecret
    accessToken : accessToken
    #refreshToken: refreshToken

  xoauthParams

exports.openMailBox = (imapConnection, mailBoxType, callback) ->
  unless imapConnection then winston.doMissingParamError 'imapConnection'; return null

  callbackCalled = false
  callbackWrapper = (error, mailBox) ->
    if callbackCalled
      winston.doWarn 'imapConnect.openMailBox double callback'
      if error
        winston.handleError error
    else
      callbackCalled = true
      callback error, mailBox

  imapConnection.connect()
  imapConnection.once 'ready', (err) ->
    if err
      imapConnect.handleOpenMailBoxReadyError err, imapConnection, callbackWrapper
    else
      imapConnect.handleOpenMailBoxReady imapConnection, mailBoxType, callbackWrapper

  imapConnection.once 'error', (err) ->
    imapConnect.handleOpenMailBoxError err, imapConnection, callbackWrapper

  imapConnection.once 'end', ->
    winston.doInfo 'Connection ended for user',
      email: imapConnection.email

  imapConnection.on 'alert', (msg) ->
    winston.doWarn 'Imap alert',
      msg: msg
      email: imapConnection.email


exports.handleOpenMailBoxReadyError = (err, imapConnection, callback ) ->
  winstonError = winston.makeError 'imap connect error',
    err: err
    email: imapConnection?.email

  if err and err.level
    winston.setErrorType winstonError, err.level

  else if err and err.source
    winston.setErrorType winstonError, err.source

  if err.source is 'timeout'
    winston.setSuppressErrorFlag winstonError, true
    winston.doWarn 'imap connect error timeout',
      err: err
      email: imapConnection?.email

  if callback
    callback winstonError


exports.handleOpenMailBoxReady = (imapConnection, mailBoxType, callback) ->
  unless imapConnection then winston.doMissingParamError 'imapConnection'; return null

  # check whether they are "Google Mail" or "GMail"
  imapConnection.getBoxes '', (getBoxesErr, boxes) ->
    if getBoxesErr then callback winston.makeError 'Could not get boxes', {err: getBoxesErr}; return
    unless boxes then callback winston.makeError 'No mailBoxes found'; return

    imapConnect.findMailBox mailBoxType, boxes, (error, fullMailBoxName) ->
      if error then callback error; return
      unless fullMailBoxName then callback winston.makeError 'no fullMailBoxName, but no error!'; return

      imapConnection.openBox fullMailBoxName, true, (openBoxErr, mailBox) ->
        if openBoxErr then callback winston.makeError 'Could not open mailBox', {err: openBoxErr}; return
        unless mailBox then callback winston.makeError 'no mailBox', {email: imapConnection.email}; return

        callback null, mailBox


exports.findMailBox = (mailBoxType, boxes, callback) ->
  unless mailBoxType then callback winston.makeMissingParamError 'mailBoxType'; return
  unless boxes then callback winston.makeMissingParamError 'boxes'; return
  mailBoxNames = conf.gmail.mailBoxNames?[mailBoxType]
  unless mailBoxNames then callback winston.makeError 'no such mailBoxNames in conf', {mailBoxType: mailBoxType}; return

  topLevelBoxName = null
  for key, value of boxes
    if key is constants.gmail.topLevelBoxName.GMAIL
      topLevelBoxName = key
    if key is constants.gmail.topLevelBoxName.GOOGLE_MAIL
      topLevelBoxName = key

  topBoxChildren = boxes[topLevelBoxName]?.children
  unless topLevelBoxName and topBoxChildren
    winstonError = winston.makeError 'Could not find candidate topLevelBoxName',
      topLevelBoxName: topLevelBoxName
      boxes: boxes
    winston.setErrorType winstonError, constants.errorType.imap.NO_BOX_TO_OPEN
    callback winstonError
    return

  for topBoxChildrenKey, topBoxChildrenValue of topBoxChildren
    attributes = topBoxChildrenValue?.attribs || []
    for attribute in attributes
      if attribute is mailBoxNames.capitalizedMailBoxName or attribute is mailBoxNames.slashedMailBoxName
        fullBoxName = topLevelBoxName + '/' + topBoxChildrenKey
        callback null, fullBoxName
        return

  winstonError = winston.makeError 'Error: Could not find mailBox'
  winston.setErrorType winstonError, constants.errorType.imap.MAIL_BOX_DOES_NOT_EXIST
  callback winstonError


exports.handleOpenMailBoxError = (err, imapConnection, callback) ->
  unless err then callback()

  winstonError = winston.makeError 'imap connect error',
    err: err
    email: imapConnection?.email

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
        email: imapConnection?.email

  callback winstonError


exports.closeMailBox = (imapConnection, callback) ->
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return
  imapConnection.closeBox callback

exports.logout = (imapConnection, callback) ->
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return
  imapConnection.end()
  callback()

exports.closeMailBoxAndLogout = (imapConnection, callback) ->
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return

  imapConnect.closeMailBox imapConnection, (error) ->
    if error then callback error; return

    imapConnect.logout imapConnection, (error) ->
      if error then callback error; return

      callback()
