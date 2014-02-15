async = require 'async'

mongooseConnect = require './mongooseConnect'
utils = require './utils'
sqsUtils = require './sqsUtils'
basicUtils = require './basicUtils'
winston = require('./winstonWrapper').winston

constants = require '../constants'

appInitUtils = this

process.on 'uncaughtException', (err) ->
  winston.doError 'uncaughtException:',
    stack: err.stack
    message: err.message
  process.exit 1

exports.initApp = ( appName, actions, callback ) =>

  winston.logBreak()
  winston.doInfo appName + ' app starting...'

  if not utils.isArray actions
    winston.doInfo appName + ' app init successful, no required actions.'
    callback()
    return

  async.each actions, appInitUtils.doInitAction, ( error ) =>
    if error
      winston.handleError error
      winston.doError appName + ' app init failed!'
      process.exit 1
    
    winston.doInfo appName + ' app init successful.'
    callback()


exports.doInitAction = ( action, callback ) =>
  unless action then callback winston.makeMissingParamError 'action'; return

  switch action

    when constants.initAction.CONNECT_MONGO
      mongooseConnect.init callback
      break
    when constants.initAction.HANDLE_SQS_WORKERS
      sqsUtils.initWorkers()
      callback()
    
    else
      callback 'invalid init action: ' + action