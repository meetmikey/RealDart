commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
emailImportUtils = require commonAppDir + '/lib/emailImportUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
UserModel = require(commonAppDir + '/schema/user').UserModel
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
EmailAccountStateModel = require(commonAppDir + '/schema/emailAccountState').EmailAccountStateModel

commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'


initActions = [
  commonConstants.initAction.CONNECT_MONGO
]


run = (callback) ->

  GoogleUserModel.find {}, (mongoError, googleUsers) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless googleUsers and googleUsers.length
      winston.doWarn 'no googleUsers found'
      callback()
      return

    async.each googleUsers, (googleUser, eachCallback) ->

      googleUserId = googleUser._id
      winston.doInfo 'processing googleUser...',
        googleUserId: googleUserId
        email: googleUser.email

      getUserAndEmailAccountState googleUser._id, (error, user, emailAccountState) ->
        if error then eachCallback error; return
        unless user then eachCallback winston.makeError 'no user'; return
        unless emailAccountState
          winston.doWarn 'no emailAccountState',
            email: googleUser.email
          eachCallback()
          return

        minUID = emailAccountState.currentUIDNext
        maxUID = minUID + commonConstants.HEADER_DOWNLOAD_BATCH_SIZE - 1

        emailImportUtils.importHeaders user._id, googleUser, minUID, maxUID, (error, uidNext) ->
          if error then eachCallback error; return
          unless uidNext then eachCallback winston.makeError 'no uidNext'; return

          #Didn't get any new mail
          if uidNext is minUID then eachCallback(); return

          update =
            $set:
              currentUIDNext: uidNext

          EmailAccountStateModel.findByIdAndUpdate emailAccountState._id, update, (mongoError) ->
            if mongoError then eachCallback winston.makeMongoError mongoError; return

            # This is a little wasteful if we didn't actually add any new contacts, but it's ok for now...
            mergeContactsJob =
              userId: userId
              createAddEmailTouchesJob: true
              googleUserId: googleUserId

            sqsUtils.addJobToQueue conf.queue.mergeContacts, mergeContactsJob, eachCallback

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


appInitUtils.initApp 'getRecentMail', initActions, run