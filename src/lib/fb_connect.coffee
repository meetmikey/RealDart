passport = require('passport')
FacebookStrategy = require('passport-facebook').Strategy
conf = require('../conf')

passport.use(new FacebookStrategy({
    clientID: conf.fb.app_id,
    clientSecret: conf.fb.app_secret,
    callbackURL: "http://local.realdart.com:3000/auth/facebook/callback",
    scope: ["user_about_me",
            "friends_about_me",
            "friends_activities",
            "friends_birthday",
            "user_checkins",
            "friends_checkins",
            "user_education_history",
            "friends_education_history",
            "user_events",
            "friends_events",
            "user_groups",
            "friends_groups",
            "user_hometown",
            "friends_hometown",
            "user_interests",
            "friends_interests",
            "user_likes",
            "friends_likes",
            "user_location",
            "friends_location",
            "friends_relationships",
            "friends_relationship_details",
            "user_religion_politics",
            "friends_religion_politics",
            "user_status",
            "friends_status",
            "user_subscriptions",
            "friends_subscriptions",
            "user_website",
            "friends_website",
            "user_work_history",
            "friends_work_history"]
  },
  (accessToken, refreshToken, profile, done) ->
    console.log accessToken
    console.log refreshToken
    console.log profile
    done(null, profile)
))


passport.serializeUser (user, done) ->
  done(null, user.id)

passport.deserializeUser (id, done) ->
  done(null, 'TODO: lookup user from storage')