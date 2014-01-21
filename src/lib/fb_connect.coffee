passport = require('passport')
FacebookStrategy = require('passport-facebook').Strategy
conf = require('../conf')

passport.use(new FacebookStrategy({
    clientID: conf.fb.app_id,
    clientSecret: conf.fb.app_secret,
    callbackURL: "http://local.realdart.com:3000/auth/facebook/callback"
  },
  (accessToken, refreshToken, profile, done) ->
    console.log accessToken
    console.log refreshToken
    console.log profile
    done()
))