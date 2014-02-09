commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston

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
    when commonConstants.service.FACEBOOK
      dataImportHelpers.doFacebookDataImportJob job, callback
    when commonConstants.service.LINKED_IN
      dataImportHelpers.doLinkedInDataImportJob job, callback
    when commonConstants.service.GMAIL
      dataImportHelpers.doGmailDataImportJob job, callback
    else
      callback winston.makeError 'invalid dataImport service',
        service: service
        job: job

exports.doFacebookDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  winston.doInfo 'doFacebookDataImportJob',
    job: job

  #TODO: write this...
  #fbHelpers.fetchAndSaveFriendData()
  callback()

exports.doLinkedInDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  winston.doInfo 'doLinkedInDataImportJob',
    job: job

  #TODO: write this...
  callback()

exports.doGmailDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  winston.doInfo 'doGmailDataImportJob',
    job: job

  #TODO: write this...
  callback()