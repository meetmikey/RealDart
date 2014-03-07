a = {}
if a and a.
  console.log 'IT IS TRUE'
else
  console.log 'IT IS FALSE'



commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

lockUtils = require commonAppDir + '/lib/lockUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require(commonAppDir + '/lib/mongooseConnect')
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

key = 'lockTest'

run = (callback) ->
  lockUtils.acquireLock key, (error, key) ->
    if error then callback error; return

    if key
      winston.doInfo 'got lock!'
      lockUtils.releaseLock key, callback
      #callback()
    else
      winston.doInfo 'failed to get lock.'
      callback()
  


postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

appInitUtils.initApp 'acquireAndReleaseLock', initActions, postInit