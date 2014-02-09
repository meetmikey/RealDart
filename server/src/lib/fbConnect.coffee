appDir = process.env['REAL_DART_HOME'] + '/app'

graph = require 'fbgraph'
passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy
winston = require('./winstonWrapper').winston
fbHelpers = require './fbHelpers.js'
routeUtils = require './routeUtils'
conf = require appDir + '/conf'

fbConnect = this

passport.use new FacebookStrategy {
    clientID: conf.fb.app_id
    clientSecret: conf.fb.app_secret
    callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/facebook/callback'
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
  } , (accessToken, refreshToken, profile, done) ->

    fbConnect.saveUserAndQueueImport accessToken, refreshToken, profile, (error) ->
      if error
        winston.handleError error
        done 'error while handling auth', profile
      else
        done null, profile

exports.saveUserAndQueueImport = (accessToken, refreshToken, profile, callback) ->

  userData = profile._json
  userData._id = userData.id
  userData.accessToken = accessToken
  userData.refreshToken = refreshToken

  select =
    _id: userData._id

  updateJSON = fbHelpers.getUpdateJSONForUser userData

  options =
    upsert: true

  FBUserModel.findOneAndUpdate select, updateJSON, options, (mongoError, user) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    sqsUtils.addMessageToQueue conf.queue.dataImport,
      service: constants.service.FACEBOOK

    , (error) ->
      callback error


    #queue job should call fbHelpers.fetchAndSaveFriendData()