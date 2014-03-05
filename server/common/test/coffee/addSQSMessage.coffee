commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

sqsUtils = require commonAppDir + '/lib/sqsUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

conf = require commonAppDir + '/conf'

queueName = conf.queue.dataImport

job =
  foo: 'bar'

sqsUtils.addJobToQueue queueName, job, (error) ->
  if error then winston.handleError error; return

  winston.doInfo 'Success.'