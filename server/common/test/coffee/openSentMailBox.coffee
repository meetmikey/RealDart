commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

imapConnect = require commonAppDir + '/lib/imapConnect'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require( commonAppDir + '/lib/winstonWrapper' ).winston
mongoose = require( commonAppDir + '/lib/mongooseConnect' ).mongoose
UserModel = require( commonAppDir + '/schema/user' ).UserModel
GoogleUserModel = require( commonAppDir + '/schema/googleUser' ).GoogleUserModel

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

userId = '52f706661edc38e84c397b2a'
googleUserIdIndex = 0

run = (callback) ->

  getUserAndGoogleUser userId, googleUserIdIndex, (error, user, googleUser) ->
    if error then callback error; return
    unless user then callback winston.makeError 'missing user'; return
    unless googleUser then callback winston.makeError 'missing googleUser'; return

    googleHelpers.getAccessToken googleUser, (error, accessToken) ->
      if error then callback error; return
      unless accessToken then callback winston.makeError 'no accessToken'; return

      imapConnect.createImapConnection googleUser.email, accessToken, (error, imapConnection) ->
        if error then callback error; return
        unless imapConnection then callback winston.makeError 'no imapConnection'; return

        sentMailBoxType = constants.gmail.mailBoxType.SENT
        imapConnect.openMailBox imapConnection, sentMailBoxType, (error, sentMailBox) ->
          if error then callback error; return

          winston.doInfo 'sentMailBox opened!',
            sentMailBox: sentMailBox

          imapConnect.closeMailBoxAndLogout imapConnection, callback


getUserAndGoogleUser = (userId, googleUserIdIndex, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUserIdIndex isnt null then callback winston.makeMissingParamError 'googleUserIdIndex'; return

  UserModel.findById userId, (error, user) ->
    if error then callback winston.makeMongoError error; return
    unless user then callback winston.makeError 'user not found', {userId: userId}; return

    googleUserIds = user.googleUserIds

    unless googleUserIds and googleUserIds.length
      callback winston.makeError 'no connected google account'
      return

    unless googleUserIds.length > googleUserIdIndex
      callback winston.makeError 'no googleUserId for index', {googleUserIdIndex: googleUserIdIndex}
      return

    googleUserId = googleUserIds[ googleUserIdIndex ]

    GoogleUserModel.findById googleUserId, (error, googleUser) ->
      if error then callback winston.makeMongoError error; return
      unless user then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

      callback null, user, googleUser


postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongoose.disconnect()
    winston.doInfo 'Done.'

appInitUtils.initApp 'openSentMailBox', initActions, postInit