appDir = process.env['REAL_DART_HOME'] + '/app'

graph = require 'fbgraph'
passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy
winston = require('./winstonWrapper').winston
FBUserModel = require(appDir + '/schema/fbUser').FBUserModel
fbHelpers = require './fbHelpers.js'
conf = require appDir + '/conf'

fbConnect = this

passport.use new FacebookStrategy {
    clientID: conf.fb.app_id
    clientSecret: conf.fb.app_secret
    callbackURL: "http://local.realdart.com:3000/auth/facebook/callback"
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
    ]
  } , (accessToken, refreshToken, profile, done) ->

    fbConnect.saveUserData accessToken, refreshToken, profile, (err) =>
        done err, profile

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  FBUserModel.findById id, (err, user) ->
    if err
      done(err)
    else 
      done null, user

exports.saveUserData = (accessToken, refreshToken, profile, callback) =>
  userData = profile._json
  userData._id = userData.id
  userData.accessToken = accessToken
  updateJSON = fbHelpers.getUpdateJSONForUser userData

  FBUserModel.findOneAndUpdate {_id : userData._id}, updateJSON, {upsert : true}, (err, fbUser) ->
    if err
      callback winston.makeError(err)
    else
      # TODO: make this a queue job to onboard the user
      fbHelpers.fetchAndSaveFriendData fbUser, (err, friends) ->
        #TODO: save friends
        callback()
