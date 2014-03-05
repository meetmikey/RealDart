commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
emailImportUtils = require commonAppDir + '/lib/emailImportUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
UserModel = require(commonAppDir + '/schema/user').UserModel
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
EmailAccountStateModel = require(commonAppDir + '/schema/emailAccountState').EmailAccountStateModel
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'

commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'


initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongooseConnect.disconnect()
    winston.doInfo 'Done.'


run = (callback) ->

  GoogleUserModel.find {}, (mongoError, googleUsers) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless googleUsers and googleUsers.length
      winston.doWarn 'no googleUsers found'
      callback()
      return

    async.eachSeries googleUsers, (googleUser, eachSeriesCallback) ->

      winston.doInfo 'processing googleUser...',
        googleUserId: googleUser._id
        email: googleUser.email

      getUserAndEmailAccountState googleUser._id, (error, user, emailAccountState) ->
        if error then eachSeriesCallback error; return
        unless user then eachSeriesCallback winston.makeError 'no user'; return
        unless emailAccountState
          winston.doWarn 'no emailAccountState',
            email: googleUser.email
          eachSeriesCallback()
          return

        minUID = emailAccountState.currentUIDNext
        maxUID = minUID + commonConstants.HEADER_BATCH_SIZE - 1

        emailImportUtils.importHeaders user._id, googleUser, minUID, maxUID, (error, uidNext) ->
          if error then eachSeriesCallback error; return
          unless uidNext then eachSeriesCallback winston.makeError 'no uidNext'; return

          update =
            $set:
              currentUIDNext: uidNext

          EmailAccountStateModel.findByIdAndUpdate emailAccountState._id, update, (mongoError) ->
            if mongoError then eachSeriesCallback winston.makeMongoError mongoError; return

            eachSeriesCallback()

    , callback


getUserAndEmailAccountState = (googleUserId, callback) ->
  unless googleUserId then callback winston.makeMissingParamError 'googleUserId'; return  

  select =
    googleUserIds:
      $in: [googleUserId]

  UserModel.findOne select, (mongoError, user) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    unless user then callback winston.makeError 'no user'; return

    select =
      userId: user._id
      googleUserId: googleUserId

    EmailAccountStateModel.findOne select, (mongoError, emailAccountState) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      callback null, user, emailAccountState



appInitUtils.initApp 'getRecentMail', initActions, postInit