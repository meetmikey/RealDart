commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
googleHelpers = require commonAppDir + '/lib/googleHelpers'
fbHelpers = require commonAppDir + '/lib/fbHelpers'
liHelpers = require commonAppDir + '/lib/liHelpers'

commonConstants = require commonAppDir + '/constants'

dataImportHelpers = this

exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  service = job.service
  unless service
    callback winston.makeError 'no service on data import job!',
      job: job
    return

  switch service
    when commonConstants.service.GOOGLE
      googleHelpers.doDataImportJob job, callback
    when commonConstants.service.FACEBOOK
      fbHelpers.doDataImportJob job, callback
    when commonConstants.service.LINKED_IN
      liHelpers.doDataImportJob job, callback
    else
      callback winston.makeError 'invalid dataImport service',
        service: service
        job: job