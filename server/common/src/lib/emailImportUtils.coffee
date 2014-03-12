async = require 'async'

winston = require('./winstonWrapper').winston
googleHelpers = require './googleHelpers'
imapConnect = require './imapConnect'
imapHelpers = require './imapHelpers'
touchHelpers = require './touchHelpers'
contactHelpers = require './contactHelpers'
EmailModel = require('../schema/email').EmailModel

constants = require '../constants'

emailImportUtils = this


# callback returns (error, uidNext), where uidNext is min( mailBox.uidnext, maxUID + 1 )
exports.importHeaders = (userId, googleUser, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless minUID > 0 then callback winston.makeMissingParamError 'minUID'; return
  unless maxUID > 0 then callback winston.makeMissingParamError 'maxUID'; return
  unless minUID <= maxUID then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return

  googleHelpers.getAccessToken googleUser, (error, accessToken) ->
    if error then callback error; return
    unless accessToken then callback winston.makeError 'no accessToken'; return

    imapConnect.createImapConnection googleUser.email, accessToken, (error, imapConnection) ->
      if error then callback error; return
      unless imapConnection then callback winston.makeError 'no imapConnection'; return

      mailBoxType = constants.gmail.mailBoxType.SENT
      imapConnect.openMailBox imapConnection, mailBoxType, (error, mailBox) ->
        if error then callback error; return

        uidNext = mailBox.uidnext
        if uidNext > maxUID
          uidNext = maxUID + 1

        imapHelpers.getHeaders userId, imapConnection, minUID, maxUID, (error, headersArray) ->

          headersArray ||= []
          async.each headersArray, (headers, eachCallback) ->
            emailImportUtils.saveHeaders userId, googleUser, headers, eachCallback

          , (error) ->
            imapConnect.closeMailBoxAndLogout imapConnection, (imapLogoutError) ->
              if imapLogoutError
                winston.handleError imapLogoutError

              callback error, uidNext


exports.saveHeaders = (userId, googleUser, headers, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless headers then callback winston.makeMissingParamError 'headers'; return

  emailJSON = headers
  emailJSON.userId = userId
  emailJSON.googleUserId = googleUser._id

  select =
    userId: emailJSON.userId
    googleUserId: emailJSON.googleUserId
    uid: emailJSON.uid

  update =
    $set: emailJSON

  options =
    upsert: true

  EmailModel.findOneAndUpdate select, update, options, (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    contactHelpers.addSourceContactsFromEmail userId, emailJSON, callback