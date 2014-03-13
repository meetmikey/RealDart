commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
workerAppDir = commonAppDir + '/../../worker/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require( commonAppDir + '/lib/winstonWrapper' ).winston
sqsUtils = require commonAppDir + '/lib/sqsUtils'

commonConstants = require commonAppDir + '/constants'
commonConf = require commonAppDir + '/conf'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
  commonConstants.initAction.HANDLE_SQS_WORKERS
]

maxWorkers = 50

testSQSJob =
  'hi!'

run = (callback) ->
  sqsUtils.pollQueue commonConf.queue.dataImport, doNothing, maxWorkers
  sqsUtils.pollQueue commonConf.queue.test, doTestJob, maxWorkers


doTestJob = (job, callback) ->
  winston.doInfo 'got job',
    job: job
  sqsUtils.addJobToQueue commonConf.queue.test, testSQSJob, callback

doNothing = (job, callback) ->
  callback()

appInitUtils.initApp 'doMailHeaderDownloadJob', initActions, run