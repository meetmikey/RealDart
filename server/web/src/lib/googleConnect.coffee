commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
googleHelpers = require commonAppDir + '/lib/googleHelpers'

routeUtils = require './routeUtils'


googleConnect = this

passport.use new GoogleStrategy
  clientID: commonConf.auth.google.clientId
  clientSecret: commonConf.auth.google.clientSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/google/callback'
  passReqToCallback: true
  , (req, accessToken, refreshToken, profile, done) ->

    userId = routeUtils.getUserIdFromAuthRequest req
    unless userId
      winston.doError 'no userId in auth req'
      done 'server error', profile
      return

    googleConnect.saveUserAndQueueImport userId, accessToken, refreshToken, profile, (error) ->
      if error
        winston.handleError error
        done 'server error', profile
      else
        done null, profile

exports.saveUserAndQueueImport = (userId, accessToken, refreshToken, profile, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless accessToken then callback winston.makeMissingParamError 'accessToken'; return
  unless profile then callback winston.makeMissingParamError 'profile'; return

  googleUser = new GoogleUserModel googleHelpers.getUserJSONFromProfile profile
  googleUser.accessToken = accessToken
  googleUser.refreshToken = refreshToken

  googleUser.save (mongoError, googleUserSaved) ->
    googleUser = googleUserSaved || googleUser
    if mongoError
      if mongoError.code isnt 11000 then callback winston.makeMongoError mongoError; return

    job =
      userId: userId
      service: commonConstants.service.GOOGLE
      googleUserId: googleUser._id

    sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback