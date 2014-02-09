commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

dataImportHelpers = require './lib/dataImportHelpers'

constants = require './constants'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
  commonConstants.initAction.HANDLE_SQS_WORKERS
]

serverWorkerApp = this

exports.postInit = () ->
  serverWorkerApp.startPolling()

exports.startPolling = () ->

  maxWorkers = constants.MAX_WORKERS_PER_QUEUE
  if process.argv and process.argv.length > 2
    maxWorkers = process.argv[2]

  for queueName of commonConf.queue
    sqsUtils.pollQueue queueName, (job, callback) ->
      serverWorkerApp.doJob job, queueName, callback
    , maxWorkers

exports.doJob = (job, queueName, callback) ->

  switch queueName
    when commonConf.queue.dataImport
      dataImportHelpers.doDataImportJob job, callback
    else
      winston.doError 'unsupported queueName',
        queueName: queueName
        job: job
      callback()

appInitUtils.initApp 'workerApp', initActions, serverWorkerApp.postInit