commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
workerAppDir = commonAppDir + '/../../worker/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require( commonAppDir + '/lib/winstonWrapper' ).winston
sqsUtils = require commonAppDir + '/lib/sqsUtils'

commonConstants = require commonAppDir + '/constants'
commonConf = require commonAppDir + '/conf'

initActions = [
]

testSQSJob =
  'hi!'

run = (callback) ->
  sqsUtils.addJobToQueue commonConf.queue.test, testSQSJob, callback

appInitUtils.initApp 'doMailHeaderDownloadJob', initActions, run