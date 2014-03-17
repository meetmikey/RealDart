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

numTestWorkers = 3
numTest2Workers = 0

testSQSJob =
  'hi!'

run = (callback) ->
  if numTestWorkers
    sqsUtils.pollQueue commonConf.queue.test, doNothingSlow, numTestWorkers
  if numTest2Workers
    sqsUtils.pollQueue commonConf.queue.test2, doNothing, numTest2Workers

printJob = (job) ->
  winston.doInfo 'got job',
    job: job

doNothing = (job, callback) ->
  printJob job
  callback()

doNothingSlow = (job, callback) ->
  printJob job
  setTimeout () ->
    callback()
  , 5000

addAnotherTestJob = (job, callback) ->
  printJob job
  sqsUtils.addJobToQueue commonConf.queue.test, testSQSJob, callback

appInitUtils.initApp 'doMailHeaderDownloadJob', initActions, run