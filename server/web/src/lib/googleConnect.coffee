commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
utils = require commonAppDir + '/lib/utils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
UserModel = require(commonAppDir + '/schema/user').UserModel
googleHelpers = require commonAppDir + '/lib/googleHelpers'

routeUtils = require './routeUtils'


googleConnect = this

passport.use new GoogleStrategy
  clientID: commonConf.auth.google.clientId
  clientSecret: commonConf.auth.google.clientSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/google/callback'
  passReqToCallback: true
  , (req, accessToken, refreshToken, profile, done) ->

    winston.doInfo 'googleConnect',
      accessToken: accessToken
      refreshToken: refreshToken

    userId = routeUtils.getUserIdFromAuthRequest req
    unless userId
      winston.doError 'no userId in auth req'
      done 'server error', profile
      return

    googleConnect.saveUserAndQueueImport userId, accessToken, refreshToken, profile, (error) ->
      if error
        winston.handleError error
        done 'server error', profile
      else
        done null, profile

exports.saveUserAndQueueImport = (userId, accessToken, refreshToken, profile, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless accessToken then callback winston.makeMissingParamError 'accessToken'; return
  unless profile then callback winston.makeMissingParamError 'profile'; return

  googleUserJSON = googleHelpers.getUserJSONFromProfile profile

  accessTokenEncryptedInfo = utils.encryptSymmetric accessToken
  googleUserJSON.accessTokenEncrypted = accessTokenEncryptedInfo.encrypted
  googleUserJSON.accessTokenSalt = accessTokenEncryptedInfo.salt
  if refreshToken
    refreshTokenEncryptedInfo = utils.encryptSymmetric refreshToken
    googleUserJSON.refreshTokenEncrypted = refreshTokenEncryptedInfo.encrypted
    googleUserJSON.refreshTokenSalt = refreshTokenEncryptedInfo.salt

  googleUserId = googleUserJSON._id
  delete googleUserJSON._id

  update =
    $set: googleUserJSON

  options =
    upsert: true

  GoogleUserModel.findByIdAndUpdate googleUserId, update, options, (mongoError, googleUser) ->
    
    if mongoError and mongoError.code isnt commonConstants.MONGO_ERROR_CODE_DUPLICATE
      callback winston.makeMongoError mongoError
      return

    select =
      _id: userId

    update =
      $addToSet:
        googleUserIds: googleUser._id

    UserModel.findOneAndUpdate select, update, (error, updatedUser) ->
      if error then callback winston.makeMongoError error; return

      job =
        userId: userId
        service: commonConstants.service.GOOGLE
        googleUserId: googleUser._id

      sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback