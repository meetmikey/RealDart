mongoose = require 'mongoose'

utils = require './utils'
winston = require('./winstonWrapper').winston
conf = require '../conf'

environment = process.env.NODE_ENV

mongooseConnect = this

exports.mongoose = mongoose

exports.init = ( callback ) =>

  mongoConf = {}

  if environment is 'production'
    mongoConf = conf.mongo.prod
  else
    mongoConf = conf.mongo.local

  connectionInfo = mongooseConnect.getConnectionInfoFromConf mongoConf

  if not connectionInfo or not connectionInfo.mongoPath
    callback winston.makeError 'no mongo path'
  else
    winston.doInfo 'mongooseConnect: mongoPath',
      path: connectionInfo.logSafeMongoPath
      useSSL: connectionInfo.useSSL

    mongoose.connect connectionInfo.mongoPath, connectionInfo.options, (mongoErr) ->
      if mongoErr
        callback mongoErr.toString()
      else
        callback()


exports.initSync = () =>

  mongoConf = {}

  if environment is 'production'
    mongoConf = conf.mongo.prod
  else
    mongoConf = conf.mongo.local

  connectionInfo = mongooseConnect.getConnectionInfoFromConf mongoConf

  if not connectionInfo or not connectionInfo.mongoPath
    winston.doError 'no mongo path'
  else
    winston.doInfo 'mongooseConnect: mongoPath',
      path: connectionInfo.logSafeMongoPath
      useSSL: connectionInfo.useSSL

    mongoose.connect connectionInfo.mongoPath, connectionInfo.options, (mongoErr) ->
      if mongoErr
        winston.doMongoError mongoErr

exports.getConnectionInfoFromConf = ( mongoConf ) =>

  fullMongoPath = ''
  logSafeMongoPath = ''
  if mongoConf.host
    fullMongoPath = mongooseConnect.getMongoPath mongoConf.host, mongoConf, true
    logSafeMongoPath = mongooseConnect.getMongoPath mongoConf.host, mongoConf, true, true

  else if mongoConf.hosts and utils.isArray( mongoConf.hosts )
    first = true
    for i in [0...mongoConf.hosts.length]
      host = mongoConf.hosts[i]
      if not first
        fullMongoPath += ','
        logSafeMongoPath += ','
      fullMongoPath += mongooseConnect.getMongoPath host, mongoConf, first
      logSafeMongoPath += mongooseConnect.getMongoPath host, mongoConf, first, true

      first = false

  useSSL = false
  if mongoConf.useSSL
    useSSL = true

  options = mongooseConnect.getConnectionOptions useSSL

  connectionInfo =
    mongoPath: fullMongoPath
    logSafeMongoPath: logSafeMongoPath
    useSSL: useSSL
    options: options
  
  connectionInfo

exports.getMongoPath = ( host, mongoConf, includeDB, hideUserAndPass ) =>
  
  if not host or not mongoConf
    return ''

  mongoPath = 'mongodb://'

  if mongoConf.user
    if hideUserAndPass
      mongoPath += '<user>'
    else
      mongoPath += mongoConf.user
    if mongoConf.pass
        mongoPath += ':'
      if hideUserAndPass
        mongoPath += '<pass>'
      else
        mongoPath += mongoConf.pass
    mongoPath += '@'

  mongoPath += host
  if mongoConf.port
    mongoPath += ':' + mongoConf.port

  if includeDB && mongoConf.db
    mongoPath += '/' + mongoConf.db

  mongoPath


exports.getConnectionOptions = ( useSSL ) =>

  options =
    server:
      socketOptions:
        keepAlive: 1
    replset:
      socketOptions:
        keepAlive: 1

  if useSSL
    #overkill, but different version of mongoose look for different flags.
    options['server']['socketOptions']['ssl'] = true
    options['server']['ssl'] = true
    options['replset']['socketOptions']['ssl'] = true
    options['replset']['ssl'] = true
    options['ssl'] = true

  options


exports.disconnect = (callback) =>
  mongoose.disconnect (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    callback()