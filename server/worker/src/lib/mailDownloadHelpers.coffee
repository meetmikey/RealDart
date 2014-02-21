commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
EmailModel = require(commonAppDir + '/schema/email').EmailModel
imapConnect = require commonAppDir + '/lib/imapConnect'
imapHelpers = require commonAppDir + '/lib/imapHelpers'
touchHelpers = require commonAppDir + '/lib/touchHelpers'
utils = require commonAppDir + '/lib/utils'
sqsUtils = require commonAppDir + '/lib/sqsUtils'

commonConstants = require commonAppDir + '/constants'
commonConf = require commonAppDir + '/conf'

workerConstants = require '../constants'

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


exports.createHeaderDownloadJobs = (userId, googleUser, minUID, maxUID, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless minUID > 0 then callback winston.makeMissingParamError 'minUID'; return
  unless maxUID > 0 then callback winston.makeMissingParamError 'maxUID'; return
  unless minUID <= maxUID then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return
  
  uidBatches = mailDownloadHelpers.getUIDBatches minUID, maxUID

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

  batchSize = workerConstants.HEADER_BATCH_SIZE
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
  unless minUID > 0 then callback winston.makeMissingParamError 'minUID'; return
  unless maxUID > 0 then callback winston.makeMissingParamError 'maxUID'; return
  unless minUID <= maxUID then callback winston.makeMissingParamError 'minUID isnt <= maxUID'; return

  accessToken = googleUser.accessToken
  email = googleUser.email
  mailBoxType = commonConstants.gmail.mailBoxType.SENT

  imapConnect.createImapConnection email, accessToken, (error, imapConnection) ->
    if error then callback error; return
    unless imapConnection then callback winston.makeError 'no imapConnection'; return

    imapConnect.openMailBox imapConnection, mailBoxType, (error, mailBox) ->
      if error then callback error; return

      imapHelpers.getHeaders userId, imapConnection, minUID, maxUID, (error, headersArray) ->

        unless headersArray and headersArray.length then callback; return

        async.each headersArray, (headers, eachCallback) ->

          mailDownloadHelpers.saveHeadersAndAddTouches userId, googleUser, headers, eachCallback

        , (error) ->
          imapConnect.closeMailBoxAndLogout imapConnection, (imapLogoutError) ->
            if imapLogoutError
              winston.handleError imapLogoutError
            callback error


exports.saveHeadersAndAddTouches = (userId, googleUser, headers, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless headers then callback winston.makeMissingParamError 'headers'; return

  emailJSON = headers
  emailJSON.userId = userId
  emailJSON.googleUserId = googleUser._id

  select =
    userId: emailJSON.userId
    googleUserId: emailJSON.googleUserId
    uid: emailJSON.uid

  update =
    $set: emailJSON

  options =
    upsert: true
    new: false

  EmailModel.findOneAndUpdate select, update, options, (mongoError, existingEmailModel) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if existingEmailModel
      callback()
    else
      touchHelpers.addTouchesFromEmail userId, emailJSON, callback
