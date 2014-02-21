commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
utils = require commonAppDir + '/lib/utils'
sqsUtils = require commonAppDir + '/lib/sqsUtils'

constants = require commonAppDir + '/constants'

mailDownloadHelpers = this

exports.doMailDownloadJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return

  userId = job.userId
  googleUserId = job.googleUserId

  winston.doInfo 'doMailDownloadJob',
    userId: userId
    googleUserId: googleUserId

  GoogleUserModel.findById googleUserId, (error, googleUser) ->
    if error then callback winston.makeMongoError error; return

    unless googleUser then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

    mailDownloadHelpers.getHeaderUIDs userId, googleUser, (error, minUID, maxUID) ->
      if error then callback error; return

      mailDownloadHelpers.createHeaderDownloadJobs userId, googleUser, minUID, maxUID, callback

exports.getHeaderUIDs = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  headerUIDs = []

  accessToken = googleUser.accessToken
  email = googleUser.email

  imapConnect.createImapConnection email, accessToken, (error, imapConnection) ->
    if error then callback error; return
    unless imapConnection then callback winston.makeError 'no imapConnection'; return

    mailBoxType = constants.gmail.mailBoxType.SENT
    imapConnect.openMailBox imapConnection, mailBoxType, (error, mailBox) ->
      if error then callback error; return
      unless imapConnection then callback winston.makeError 'no mailBox'; return

      minUID = 0
      maxUID = 0
      if mailBox.uidnext
        maxUID = mailBox.uidnext - 1

      winston.doInfo 'got sent mailBox',
        mailBox: mailBox
        minUID: minUID
        maxUID: maxUID

      callback null, minUID, maxUID

exports.createHeaderDownloadJobs = (userId, googleUser, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  unless uids and utils.isArray uids
    winston.doWarn 'mailDownloadHelpers.createHeaderDownloadJobs: empty uids array',
      userId: userId
    callback()
    return
  
  uidBatches = mailDownloadHelpers.getUIDBatches minUID, maxUID

  async.each uidBatches, (uidBatch, eachCallback) ->

    mailHeaderDownloadJob =
      userId: userId
      googleUserId: googleUser._id
      uidBatch: uidBatch

    sqsUtils.addJobToQueue conf.queue.mailHeaderDownload, mailHeaderDownloadJob, eachCallback

  , callback


exports.getUIDBatches = ( minUID, maxUID, batchSizeInput ) ->
  uidBatches = []

  unless ( ( minUID is 0 ) or ( minUID > 0 ) ) and ( ( maxUID is 0 ) or ( maxUID > 0 ) ) and ( maxUID >= minUID )
    winston.doWarn 'invalid minUID and maxUID',
      minUID: minUID
      maxUID: maxUID
    return uidBatches

  batchSize = constants.HEADER_BATCH_SIZE
  if batchSizeInput
    batchSize = batchSizeInput

  winston.doInfo 'batchSize',
    batchSize: batchSize

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

  winston.doInfo 'doMailHeaderDownloadJob',
    userId: userId
    googleUserId: googleUserId
    uidBatch: uidBatch

  GoogleUserModel.findById googleUserId, (error, googleUser) ->
    if error then callback winston.makeMongoError error; return
    unless googleUser then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

    mailDownloadHelpers.downloadHeaders userId, googleUser, uidBatch.minUID, uidBatch.maxUID, callback


exports.downloadHeaders = (userId, googleUser, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless ( minUID is 0 ) or ( minUID > 0 )  then callback winston.makeMissingParamError 'minUID'; return
  unless ( maxUID is 0 ) or ( maxUID > 0 )  then callback winston.makeMissingParamError 'maxUID'; return
  unless ( minUID <= maxUID ) then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return

  #TODO: write this...

  callback()