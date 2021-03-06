commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
EmailAccountStateModel = require(commonAppDir + '/schema/emailAccountState').EmailAccountStateModel
EmailModel = require(commonAppDir + '/schema/email').EmailModel
imapConnect = require commonAppDir + '/lib/imapConnect'
imapHelpers = require commonAppDir + '/lib/imapHelpers'
touchHelpers = require commonAppDir + '/lib/touchHelpers'
googleHelpers = require commonAppDir + '/lib/googleHelpers'
utils = require commonAppDir + '/lib/utils'
emailImportUtils = require commonAppDir + '/lib/emailImportUtils'
sqsUtils = require commonAppDir + '/lib/sqsUtils'

commonConstants = require commonAppDir + '/constants'
commonConf = require commonAppDir + '/conf'

mailDownloadHelpers = this


exports.doMailDownloadJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return

  userId = job.userId
  googleUserId = job.googleUserId

  GoogleUserModel.findById googleUserId, (error, googleUser) ->
    if error then callback winston.makeMongoError error; return

    unless googleUser then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

    mailDownloadHelpers.getHeaderUIDs userId, googleUser, (error, minUID, maxUID) ->
      if error then callback error; return

      mailDownloadHelpers.createEmailAccountStateAndHeaderDownloadJobs userId, googleUser, minUID, maxUID, callback


exports.getHeaderUIDs = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  googleHelpers.getAccessToken googleUser, (error, accessToken) ->
    if error then callback error; return
    unless accessToken then callback winston.makeError 'no accessToken'; return

    imapConnect.createImapConnection googleUser.email, accessToken, (error, imapConnection) ->
      if error then callback error; return
      unless imapConnection then callback winston.makeError 'no imapConnection'; return

      mailBoxType = commonConstants.gmail.mailBoxType.SENT
      imapConnect.openMailBox imapConnection, mailBoxType, (error, mailBox) ->
        if error then callback error; return
        unless imapConnection then callback winston.makeError 'no mailBox'; return

        minUID = 1
        maxUID = 1
        if mailBox.uidnext
          maxUID = mailBox.uidnext - 1

        imapConnect.closeMailBoxAndLogout imapConnection, (error) ->
          callback error, minUID, maxUID


exports.createEmailAccountStateAndHeaderDownloadJobs = (userId, googleUser, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless minUID > 0 then callback winston.makeMissingParamError 'minUID'; return
  unless maxUID > 0 then callback winston.makeMissingParamError 'maxUID'; return
  unless minUID <= maxUID then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return
  
  uidBatches = mailDownloadHelpers.getUIDBatches minUID, maxUID
  emailAccountState = new EmailAccountStateModel
    userId: userId
    googleUserId: googleUser._id
    accountType: 'google'
    outstandingInitialUIDBatches: uidBatches
    originalUIDNext: maxUID + 1 # the maxUID passed here is to be downloaded, so the uidNext is maxUID + 1
    currentUIDNext: maxUID + 1 # same as originalUIDNext

  emailAccountState.save (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    async.each uidBatches, (uidBatch, eachCallback) ->

      mailHeaderDownloadJob =
        userId: userId
        googleUserId: googleUser._id
        uidBatch: uidBatch

      sqsUtils.addJobToQueue commonConf.queue.mailHeaderDownload, mailHeaderDownloadJob, eachCallback

    , callback


exports.getUIDBatches = ( minUID, maxUID, batchSizeInput ) ->
  uidBatches = []

  unless ( minUID > 0 ) and ( maxUID > 0 ) and ( maxUID >= minUID )
    winston.doWarn 'invalid minUID and maxUID',
      minUID: minUID
      maxUID: maxUID
    return uidBatches

  batchSize = commonConstants.HEADER_DOWNLOAD_BATCH_SIZE
  if batchSizeInput
    batchSize = batchSizeInput

  batchIndex = 0
  while true
    minBatchUID = minUID + ( batchIndex * batchSize )
    if minBatchUID > maxUID
      break

    maxBatchUID = minBatchUID + ( batchSize - 1 )
    if maxBatchUID > ( maxUID - 1 )
      maxBatchUID = maxUID

    uidBatch =
      minUID: minBatchUID
      maxUID: maxBatchUID
    uidBatches.push uidBatch
    batchIndex++

  uidBatches


exports.doMailHeaderDownloadJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return
  unless job.uidBatch then callback winston.makeMissingParamError 'job.uidBatch'; return

  userId = job.userId
  googleUserId = job.googleUserId
  uidBatch = job.uidBatch

  GoogleUserModel.findById googleUserId, (error, googleUser) ->
    if error then callback winston.makeMongoError error; return
    unless googleUser then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

    emailImportUtils.importHeaders userId, googleUser, uidBatch.minUID, uidBatch.maxUID, (error) ->
      if error then callback error; return

      mailDownloadHelpers.updateEmailAccountStateWithFinishedUIDBatch userId, googleUserId, uidBatch, (error, emailAccountState) ->
        if error then callback error; return

        unless emailAccountState
          winston.doError 'no emailAccountState',
            userId: userId
            googleUserId: googleUserId

        if emailAccountState?.outstandingInitialUIDBatches and emailAccountState.outstandingInitialUIDBatches.length > 0
          # There are still outstanding uid batches.  We should wait before doing the mergeContacts + addEmailTouches jobs.
          callback()
          return
        
        # This was the last uid batch!  Kick off a merge job, and tell it to do an addTouchesJob when done.
        mergeContactsJob =
          userId: userId
          createAddEmailTouchesJob: true
          googleUserId: googleUserId
        
        sqsUtils.addJobToQueue commonConf.queue.mergeContacts, mergeContactsJob, callback


exports.updateEmailAccountStateWithFinishedUIDBatch = (userId, googleUserId, uidBatch, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUserId then callback winston.makeMissingParamError 'googleUserId'; return
  unless uidBatch then callback winston.makeMissingParamError 'uidBatch'; return

  select =
    userId: userId
    googleUserId: googleUserId
    accountType: 'google'

  update =
    $pull:
      outstandingInitialUIDBatches:
        minUID: uidBatch.minUID
        maxUID: uidBatch.maxUID

  EmailAccountStateModel.findOneAndUpdate select, update, (mongoError, emailAccountState) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    callback null, emailAccountState