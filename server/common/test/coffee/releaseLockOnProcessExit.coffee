commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

lockUtils = require commonAppDir + '/lib/lockUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

key = 'releaseLockOnExitTest'

run = (callback) ->
  lockUtils.acquireLock key, (error, key) ->
    if error then callback error; return

    if key
      winston.doInfo 'got lock!'
      callback()
    else
      winston.doInfo 'failed to get lock.'
      callback()
  

appInitUtils.initApp 'releaseLockOnProcessExit', initActions, run