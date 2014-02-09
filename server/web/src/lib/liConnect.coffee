commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
LinkedInStrategy = require('passport-linkedin').Strategy
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
liHelpers = require commonAppDir + '/lib/liHelpers'

routeUtils = require './routeUtils'


liConnect = this

passport.use new LinkedInStrategy
  consumerKey: commonConf.li.apiKey
  consumerSecret: commonConf.li.apiSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/linkedIn/callback'
  , (token, tokenSecret, profile, done) ->
    liConnect.saveUserAndQueueImport token, tokenSecret, profile, (error) ->
      if error
        winston.handleError error
        done 'server error', profile
      else
        done null, profile

exports.saveUserAndQueueImport = (token, tokenSecret, profile, callback) ->

  liUserId =  profile.id
  liUserJSON = liHelpers.getUserJSONFromProfile profile
  liUserJSON.token = token
  liUserJSON.tokenSecret = tokenSecret

  select =
    _id: liUserId

  update =
    $set: liUserJSON

  options =
    upsert: true

  LIUserModel.findOneAndUpdate select, update, options, (mongoError, liUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    job =
      service: commonConstants.service.LINKED_IN
      liUserId: liUser._id

    sqsUtils.addJobToQueue commonConf.queue.dataImport, job, callback