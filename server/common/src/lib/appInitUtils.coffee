async = require 'async'

mongooseConnect = require './mongooseConnect'
utils = require './utils'
sqsUtils = require './sqsUtils'
winston = require('./winstonWrapper').winston

appInitUtils = this

exports.CONNECT_MONGO = 'mongoConnect'

process.on 'uncaughtException', (err) ->
  winston.doError 'uncaughtException:',
    stack: err.stack
    message: err.message
  process.exit 1

process.on 'SIGUSR2', () ->
  sqsUtils.stopSignal()

exports.initApp = ( appName, actions, callback ) =>

  winston.logBreak()
  winston.doInfo appName + ' app starting...'

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