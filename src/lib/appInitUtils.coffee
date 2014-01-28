async = require 'async'

mongooseConnect = require './mongooseConnect'
utils = require './utils'
winston = require('./winstonWrapper').winston

environment = process.env.NODE_ENV
appInitUtils = this

exports.CONNECT_MONGO = 'mongoConnect'

exports.initApp = ( appName, actions, callback ) =>

  winston.logBreak()
  winston.doInfo appName + ' app starting...'

  winston.doInfo 'utils',
    utils: utils

  if not utils.isArray actions
    winston.doInfo appName + ' app init successful, no required actions.'
    callback()

  else
    async.each actions, appInitUtils.doInitAction, ( err ) =>
      if err
        winston.doError appName + ' app init failed!', {err: err}
        process.exit 1

      else
        winston.doInfo appName + ' app init successful'
        callback()


exports.doInitAction = ( action, callback ) =>

  if not action
    callback 'no param: action'
    return

  switch action

    when appInitUtils.CONNECT_MONGO
      mongooseConnect.init callback
      break
    
    else
      callback 'invalid init action: ' + action