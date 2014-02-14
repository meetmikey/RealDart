commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
LinkedInStrategy = require('passport-linkedin-oauth2').Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
liHelpers = require commonAppDir + '/lib/liHelpers'

routeUtils = require './routeUtils'


liConnect = this

passport.use new LinkedInStrategy
  clientID: commonConf.auth.linkedIn.apiKey
  clientSecret: commonConf.auth.linkedIn.apiSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/linkedIn/callback'
  passReqToCallback: true
  scope: commonConf.auth.linkedIn.scope
  , (req, token, tokenSecret, profile, done) ->

    userId = routeUtils.getUserIdFromAuthRequest req
    unless userId
      winston.doError 'no userId in auth req'
      done 'server error', profile
      return

    liConnect.saveUserAndQueueImport userId, token, tokenSecret, profile, (error) ->
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

  liUser = new LIUserModel liHelpers.getUserJSONFromProfile profile
  liUser.accessToken = accessToken
  liUser.refreshToken = refreshToken


  winston.doInfo 'li accessToken',
    accessToken: accessToken

  liUser.save (mongoError, liUserSaved, numAffected) ->
    
    winston.doInfo 'liUserSaved',
      liUserSaved: liUserSaved
      numAffected: numAffected

    liUser = liUserSaved || liUser
    if mongoError and mongoError.code isnt commonConstants.MONGO_ERROR_CODE_DUPLICATE
      callback winston.makeMongoError mongoError
      return

    job =
      userId: userId
      service: commonConstants.service.LINKED_IN
      liUserId: liUser._id

    sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback