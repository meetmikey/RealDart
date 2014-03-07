commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
contactHelpers = require commonAppDir + '/lib/contactHelpers'

commonConstants = require commonAppDir + '/constants'

cleanupContactHelpers = this


exports.doMergeContactsJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  userId = job.userId
  unless userId then callback winston.makeError 'no userId', {job: job}; return

  contactHelpers.mergeContacts userId, callback


exports.doImportContactImagesJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  userId = job.userId
  unless userId then callback winston.makeError 'no userId', {job: job}; return

  contactHelpers.importContactImages userId, callback