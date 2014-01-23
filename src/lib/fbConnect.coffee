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
  updateJSON = fbConnect.getUpdateJSON userData

  console.log updateJSON

  FBUserModel.findOneAndUpdate {_id : userData._id}, updateJSON, {upsert : true}, (err, fbUser) ->
    if err
      console.log 'an error occurred', err
      callback winston.makeError(err)
    else
      console.log 'new user', fbUser
      fbConnect.fetchAndSaveFriendData fbUser, callback

exports.getUpdateJSON = (userData) =>
  updateJSON = {'$set' : {}}
  for k, v of userData
    if k != '_id'
      updateJSON['$set'][k] = v
  updateJSON

exports.fetchAndSaveFriendData = (fbUser, callback) =>
  console.log 'fetchAndSaveFriendData'
  query =
    friends: 'SELECT uid, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())'

  graph.fql query, (err, res) ->
    winston.doInfo 'FB graph query response',
      res: res
