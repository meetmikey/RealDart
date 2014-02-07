appDir = process.env['REAL_DART_HOME'] + '/app'

graph = require 'fbgraph'
passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy
winston = require('./winstonWrapper').winston
FBUserModel = require(appDir + '/schema/fbUser').FBUserModel
UserModel = require(appDir + '/schema/user').UserModel
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

    fbConnect.saveUserData accessToken, refreshToken, profile, (error) =>
      if error
        winston.handleError error
        done 'internal error', profile
      else
        done null, profile

exports.saveUserData = (accessToken, refreshToken, profile, callback) =>

  userData = profile._json
  userData._id = userData.id
  userData.accessToken = accessToken
  updateJSON = fbHelpers.getUpdateJSONForUser userData

  # save a user object
  UserModel.findOneAndUpdate {fbUserId : userData._id}, 
    {$set : {fbUserId : userData._id, firstName : userData.first_name, lastName : userData.last_name}},
    {upsert : true},
    (mongoError, user) ->

      if mongoError then callback winston.makeMongoError mongoError; return

      # save a fb user object
      FBUserModel.findOneAndUpdate {_id : userData._id}, updateJSON, {upsert : true}, (err, fbUser) ->
        if err
          callback winston.makeMongoError(err)
        else
          fbHelpers.fetchAndSaveFriendData fbUser, (err, friends) ->
            #TODO: save friends
            callback()
