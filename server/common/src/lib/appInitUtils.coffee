async = require 'async'

mongooseConnect = require './mongooseConnect'
utils = require './utils'
sqsUtils = require './sqsUtils'
lockUtils = require './lockUtils'
basicUtils = require './basicUtils'
winston = require('./winstonWrapper').winston

constants = require '../constants'

appInitUtils = this

process.on 'uncaughtException', (err) ->
  winstonError = winston.makeError 'uncaughtException:',
    stack: err.stack
    message: err.message
  appInitUtils._shutdownApp winstonError, 1

process.on 'SIGINT', () ->
  appInitUtils._shutdownApp()

initActions = []


# Callback here is unique.  It will never call back with an error.
#  Instead, it calls back with the function to call when the app is done running.
exports.initApp = ( appName, actions, callback ) =>

  winston.logBreak()
  initActions = actions
  winston.doInfo appName + ' app starting...'

  if not utils.isArray actions
    winston.doInfo appName + ' app init successful, no required actions.'
    callback appInitUtils._shutdownApp
    return

  async.each actions, appInitUtils._doInitAction, ( error ) =>
    if error
      # Handle this error and shutdown the app.
      winston.handleError error

      winstonError = winston.makeError appName + ' app init failed!'
      appInitUtils._shutdownApp winstonError, 1
    
    winston.doInfo appName + ' app init successful.'
    callback appInitUtils._shutdownApp



# PRIVATE
###########################


exports._doInitAction = (action, callback) =>
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


exports._doShutdownAction = (action, callback) ->
  unless action then callback winston.makeMissingParamError 'action'; return

  switch action

    when constants.initAction.CONNECT_MONGO
      mongooseConnect.disconnect callback
      break
    
    else
      callback()


exports._shutdownApp = (error, processExitCodeInput) ->
  if error then winston.handleError error

  processExitCode = 0
  if processExitCodeInput
    processExitCode = processExitCodeInput

  lockUtils.releaseAllProcessLocks () ->

    async.each initActions, (initAction, eachCallback) ->
      appInitUtils._doShutdownAction initAction, (error) ->
        if error then winston.handleError error
        eachCallback()

    , (error) ->
      process.exit processExitCode