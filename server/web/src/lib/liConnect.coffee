commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
LinkedInStrategy = require('passport-linkedin-oauth2').Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
utils = require commonAppDir + '/lib/utils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
UserModel = require(commonAppDir + '/schema/user').UserModel
liHelpers = require commonAppDir + '/lib/liHelpers'

routeUtils = require './routeUtils'


liConnect = this

passport.use new LinkedInStrategy
  clientID: commonConf.auth.linkedIn.apiKey
  clientSecret: commonConf.auth.linkedIn.apiSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/linkedIn/callback'
  passReqToCallback: true
  scope: commonConf.auth.linkedIn.scope
  , (req, token, tokenSecret, profile, done) ->

    userId = routeUtils.getUserIdFromAuthRequest req
    unless userId
      winston.doError 'no userId in auth req'
      done 'server error', profile
      return

    liConnect.saveUserAndQueueImport userId, token, tokenSecret, profile, (error) ->
      if error
        winston.handleError error
        done 'server error', profile
      else
        done null, profile

exports.saveUserAndQueueImport = (userId, accessToken, refreshToken, profile, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless accessToken then callback winston.makeMissingParamError 'accessToken'; return
  unless profile then callback winston.makeMissingParamError 'profile'; return
  unless profile.id then callback winston.makeMissingParamError 'profile.id'; return

  liUserJSON = liHelpers.getUserJSONFromProfile profile

  accessTokenEncryptedInfo = utils.encryptSymmetric accessToken
  liUserJSON.accessTokenEncrypted = accessTokenEncryptedInfo.encrypted
  liUserJSON.accessTokenSalt = accessTokenEncryptedInfo.salt
  if refreshToken
    refreshTokenEncryptedInfo = utils.encryptSymmetric refreshToken
    liUserJSON.refreshTokenEncrypted = refreshTokenEncryptedInfo.encrypted
    liUserJSON.refreshTokenSalt = refreshTokenEncryptedInfo.salt

  liUserId = liUserJSON._id
  delete liUserJSON._id

  update =
    $set: liUserJSON

  options =
    upsert: true

  LIUserModel.findByIdAndUpdate liUserId, update, options, (mongoError, liUser) ->
    if mongoError and mongoError.code isnt commonConstants.MONGO_ERROR_CODE_DUPLICATE
      callback winston.makeMongoError mongoError
      return

    select =
      _id: userId

    update =
      $set:
        liUserId: liUser._id

    UserModel.findOneAndUpdate select, update, (error, updatedUser) ->
      if error then callback winston.makeMongoError error; return

      job =
        userId: userId
        service: commonConstants.service.LINKED_IN
        liUserId: liUser._id

      sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback