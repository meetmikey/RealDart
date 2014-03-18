commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
sqsUtils = require commonAppDir + '/lib/sqsUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

conf = require commonAppDir + '/conf'
constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.HANDLE_SQS_WORKERS
]

doNothing = (job, callback) ->
  winston.doInfo 'clearing job'
  callback()

numWorkers = 10

run = (callback) ->
  for queueName of conf.queue
    sqsUtils.pollQueue queueName, doNothing, 10


appInitUtils.initApp 'clearQueues', initActions, run