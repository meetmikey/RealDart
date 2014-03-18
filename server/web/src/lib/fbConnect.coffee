commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

winston = require(commonAppDir + '/lib/winstonWrapper').winston
fbHelpers = require commonAppDir + '/lib/fbHelpers.js'
sqsUtils = require commonAppDir + '/lib/sqsUtils.js'
utils = require commonAppDir + '/lib/utils.js'
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
UserModel = require(commonAppDir + '/schema/user').UserModel
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

routeUtils = require './routeUtils'

fbConnect = this

passport.use new FacebookStrategy {
    clientID: commonConf.auth.facebook.app_id
    clientSecret: commonConf.auth.facebook.app_secret
    callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/facebook/callback'
    passReqToCallback: true
    scope: [
      "user_about_me"
      "user_birthday"
      "friends_about_me"
      "friends_activities"
      "friends_birthday"
      "user_checkins"
      "friends_checkins"
      "user_education_history"
      "friends_education_history"
      "user_events"
      "friends_events"
      "user_groups"
      "friends_groups"
      "user_hometown"
      "friends_hometown"
      "user_interests"
      "friends_interests"
      "user_likes"
      "friends_likes"
      "user_location"
      "friends_location"
      "friends_relationships"
      "friends_relationship_details"
      "user_religion_politics"
      "friends_religion_politics"
      "user_status"
      "friends_status"
      "user_subscriptions"
      "friends_subscriptions"
      "user_website"
      "friends_website"
      "user_work_history"
      "friends_work_history"
      "email"
    ]
  }
  , (req, accessToken, refreshToken, profile, done) ->

    userId = routeUtils.getUserIdFromAuthRequest req
    unless userId
      winston.doError 'no userId in auth req'
      done 'server error', profile
      return

    fbConnect.saveUserAndQueueImport userId, accessToken, refreshToken, profile, (error) ->
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

  fbUserJSON = fbHelpers.getUserJSONFromProfile profile
  fbUserJSON.timestamp = Date.now()

  accessTokenEncryptedInfo = utils.encryptSymmetric accessToken
  fbUserJSON.accessTokenEncrypted = accessTokenEncryptedInfo.encrypted
  fbUserJSON.accessTokenIV = accessTokenEncryptedInfo.iv
  if refreshToken
    refreshTokenEncryptedInfo = utils.encryptSymmetric refreshToken
    fbUserJSON.refreshTokenEncrypted = refreshTokenEncryptedInfo.encrypted
    fbUserJSON.refreshTokenIV = refreshTokenEncryptedInfo.iv

  fbUserId = fbUserJSON._id
  delete fbUserJSON._id

  update =
    $set: fbUserJSON

  options =
    upsert: true

  FBUserModel.findByIdAndUpdate fbUserId, update, options, (mongoError, fbUser) ->
    if mongoError and mongoError.code isnt commonConstants.MONGO_ERROR_CODE_DUPLICATE
      callback winston.makeMongoError mongoError
      return

    select =
      _id: userId

    update =
      $set:
        fbUserId: fbUser._id

    UserModel.findOneAndUpdate select, update, (error, updatedUser) ->
      if error then callback winston.makeMongoError error; return

      job =
        userId: userId
        service: commonConstants.service.FACEBOOK
        fbUserId: fbUser._id

      sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback