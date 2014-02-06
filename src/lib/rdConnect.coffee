appDir = process.env['REAL_DART_HOME'] + '/app'

passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
winston = require('./winstonWrapper').winston
UserModel = require(appDir + '/schema/user').UserModel
conf = require appDir + '/conf'

rdConnect = this


passport.use new LocalStrategy
  usernameField: 'email'
  passwordField: 'password'
  , (email, password, done) ->
    UserModel.findOne { email: email }, (err, user) ->
      if err then return done err

      if not user
        return done null, false, { message: 'Incorrect username.' }
      
      if not user.validPassword password
        return done null, false, { message: 'Incorrect password.' }

      return done null, user


passport.serializeUser (user, done) ->
  winston.doInfo 'serializeUser',
    user: user

  done null, user._id

passport.deserializeUser (id, done) ->
  UserModel.findById id, (mongoError, user) ->
    if err
      winston.doMongoError mongoError
      done 'internal error: user lookup failed during deserialization', user
    else 
      done null, user