commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston

dataImportHelpers = this

exports.doDataImportJob = (job, callback) ->

  winston.doInfo 'doDataImportJob...',
    job: job
    
  #TODO: write this...

  callback()