commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

passport = require 'passport'
LinkedInStrategy = require('passport-linkedin').Strategy
commonConf = require commonAppDir + '/conf'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel

routeUtils = require './routeUtils'


liConnect = this

passport.use new LinkedInStrategy
  consumerKey: commonConf.li.apiKey
  consumerSecret: commonConf.li.apiSecret
  callbackURL: routeUtils.getProtocolHostAndPort() + '/auth/linkedIn/callback'
  , (token, tokenSecret, profile, done) ->
    liConnect.saveUserData token, tokenSecret, profile, (error, liUser) ->
      if error
        winston.handleError error
        done 'internal error', liUser
      else
        done null, liUser

exports.saveUserData = (token, tokenSecret, profile, callback) ->
  winston.doInfo 'saveUserData',
    token: token
    tokenSecret: tokenSecret
    profile: profile 

  liUser = new LIUserModel profile
  liUser._id =  profile.id
  liUser.token = token
  liUser.tokenSecret = tokenSecret

  LIUserModel.findOneAndUpdate
      _id: liUser._id
    , {
      $set:
         displayName: liUser.displayName
         name: liUser.name
    }
    , upsert: true
    , (mongoError) ->
        if mongoError then callback winston.makeMongoError(mongoError), liUser; return

        callback null, liUser