commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
sqsUtils = require commonAppDir + '/lib/sqsUtils'
commonConf = require commonAppDir + '/conf'
commonConstants = require commonAppDir + '/constants'

dataImportHelpers = require './lib/dataImportHelpers'
mailDownloadHelpers = require './lib/mailDownloadHelpers'
cleanupContactHelpers = require './lib/cleanupContactHelpers'

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

  sqsUtils.pollQueue commonConf.queue.mergeContacts, cleanupContactHelpers.doMergeContactsJob, maxWorkers
  sqsUtils.pollQueue commonConf.queue.importContactImages, cleanupContactHelpers.doImportContactImagesJob, maxWorkers
  sqsUtils.pollQueue commonConf.queue.dataImport, dataImportHelpers.doDataImportJob, maxWorkers
  sqsUtils.pollQueue commonConf.queue.mailDownload, mailDownloadHelpers.doMailDownloadJob, maxWorkers
  sqsUtils.pollQueue commonConf.queue.mailHeaderDownload, mailDownloadHelpers.doMailHeaderDownloadJob, maxWorkers

appInitUtils.initApp 'workerApp', initActions, serverWorkerApp.postInit