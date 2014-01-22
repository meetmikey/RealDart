graph = require 'fbgraph'
passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

winston = require('./winstonWrapper').winston
FBUserModel = require('../schema/fbUser').FBUserModel
conf = require '../conf'

fbConnect = this

passport.use new FacebookStrategy {
    clientID: conf.fb.app_id
    clientSecret: conf.fb.app_secret
    callbackURL: "http://local.realdart.com:3000/auth/facebook/callback"
    scope: [
      "user_about_me"
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
    winston.doInfo 'FB User info...',
    accessToken: accessToken
    refreshToken: refreshToken
    profile: profile

    fbConnect.fetchAndSaveUserData accessToken, refreshToken, profile, () =>
        done null, profile

    done null, profile


passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  done null, 'TODO: lookup user from storage'


exports.fetchAndSaveUserData = (accessToken, refreshToken, profile, callback) =>

  userData = profile
  userData.refreshToken = refreshToken
  userData.accessToken = accessToken

  fbUser = new FBUserModel userData
  fbUser.save (mongoError) =>
    if mongoError
      callback mongoError.toString()
    else
      fbConnect.fetchAndSaveFriendData fbUser, callback

exports.fetchAndSaveFriendData = (fbUser, callback) =>

  query =
    friends: 'SELECT uid, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())'

  graph.fql query, (err, res) ->
    winston.doInfo 'FB graph query response',
      res: res
