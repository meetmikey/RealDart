commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

lockUtils = require commonAppDir + '/lib/lockUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require(commonAppDir + '/lib/mongooseConnect')
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

key = 'testLock'
lockHolderInfo =
  description: 'acquireAndReleaseLock test'

run = (callback) ->
  lockUtils.acquireLock key, lockHolderInfo, (error, key) ->
    if error then callback error; return

    if key
      winston.doInfo 'got lock!'
      #lockUtils.releaseLock key, callback
      #callback()
    else
      winston.doInfo 'failed to get lock.'
      callback()


appInitUtils.initApp 'acquireAndReleaseLock', initActions, run