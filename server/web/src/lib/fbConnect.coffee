commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

winston = require(commonAppDir + '/lib/winstonWrapper').winston
fbHelpers = require commonAppDir + '/lib/fbHelpers.js'
sqsUtils = require commonAppDir + '/lib/sqsUtils.js'
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
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

  fbUser = new FBUserModel fbHelpers.getUserJSONFromProfile profile
  fbUser.accessToken = accessToken
  fbUser.refreshToken = refreshToken

  fbUser.save (mongoError, fbUserSaved) ->
    fbUser = fbUserSaved || fbUser
    if mongoError
      if mongoError.code isnt 11000 then callback winston.makeMongoError mongoError; return

    job =
      userId: userId
      service: commonConstants.service.FACEBOOK
      fbUserId: fbUser._id

    sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback