commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
contactHelpers = require commonAppDir + '/lib/contactHelpers'

commonConstants = require commonAppDir + '/constants'

cleanupContactHelpers = this


exports.doMergeContactsJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  userId = job.userId
  createAddTouchesJob = job.createAddTouchesJob
  googleUserId = job.googleUserId
  unless userId then callback winston.makeError 'no userId', {job: job}; return

  contactHelpers.mergeAllContacts userId, (error) ->
    if error then callback error; return

    unless createAddTouchesJob and googleUserId
      # Nothing special to do.
      callback()
      return

    # This is a special case where this mergeContacts job was added by the last mailHeaderDownload job
    #  for an email account.  So all the emails have been downloaded and all the sourceContacts have been added.
    #  Now that we're done merging contacts, we kick off an addEmailTouchesJob that will
    #  add touches for all the emails in the account.
    addEmailTouchesJob =
      userId: userId
      googleUserId: googleUserId

    sqsUtils.addJobToQueue conf.queue.addEmailTouches, addEmailTouchesJob, callback


exports.doImportContactImagesJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  userId = job.userId
  unless userId then callback winston.makeError 'no userId', {job: job}; return

  contactHelpers.importContactImages userId, callback