commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
googleHelpers = require commonAppDir + '/lib/googleHelpers'

routeUtils = require './routeUtils'


googleConnect = this

passport.use new GoogleStrategy
  returnURL: routeUtils.getProtocolHostAndPort() + '/auth/google/callback'
  realm: routeUtils.getProtocolHostAndPort()
  , (identifierURL, profile, done) ->
      googleConnect.saveUserAndQueueImport identifierURL, profile, (error) ->
        if error
          winston.handleError error
          done 'server error', profile
        else
          done null, profile

exports.saveUserAndQueueImport = (identifierURL, profile, callback) ->

  unless identifierURL then callback winston.makeMissingParamError 'identifierURL'; return
  unless profile then callback winston.makeMissingParamError 'profile'; return

  googleUserId =  googleConnect.getGoogleUserIdFromIdentifierURL identifierURL
  unless googleUserId then callback winston.makeMissingParamError 'googleUserId'; return

  googleUser = new GoogleUserModel googleHelpers.getUserJSONFromProfile profile
  googleUser._id = googleUserId

  googleUser.save (mongoError, googleUserSaved) ->
    googleUser = googleUserSaved || googleUser
    if mongoError
      if mongoError.code isnt 11000 then callback winston.makeMongoError mongoError; return

    job =
      service: commonConstants.service.GOOGLE
      googleUserId: googleUser._id

    sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback

exports.getGoogleUserIdFromIdentifierURL = (identifierURL) ->
  unless identifierURL then return null

  #Example identifierURL:
  #"https://www.google.com/accounts/o8/id?id=AItOawn6EEiSsZRqLT1kEMQ8XeHgL2wMsbk5MLo"

  indicator = 'id='
  indicatorIndex = identifierURL.indexOf indicator
  if indicator is -1
    return null

  googleUserId = identifierURL.substring indicatorIndex + indicator.length
  googleUserId