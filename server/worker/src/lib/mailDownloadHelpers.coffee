commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
utils = require commonAppDir + '/lib/utils'
sqsUtils = require commonAppDir + '/lib/sqsUtils'

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

    mailDownloadHelpers.getHeaderUIDs userId, googleUser, (error, uids) ->
      if error then callback error; return

      mailDownloadHelpers.createHeaderDownloadJobs userId, googleUser, uids, callback

exports.getHeaderUIDs = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  headerUIDs = []

  #TODO: write this...
  imapConection = imapConnect.

  callback null, headerUIDs

exports.createHeaderDownloadJobs = (userId, googleUser, uids, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  unless uids and utils.isArray uids
    winston.doWarn 'mailDownloadHelpers.createHeaderDownloadJobs: empty uids array',
      userId: userId
    callback()
    return
  
  uidBatches = []
  while uids and uids.length
    uidBatches.push uids.splice 0, constants.HEADER_BATCH_SIZE

  async.each uidBatches, (uidBatch, eachCallback) ->

    mailHeaderDownloadJob =
      userId: userId
      googleUserId: googleUser._id
      uidBatch: uidBatch

    sqsUtils.addJobToQueue conf.queue.mailHeaderDownload, mailHeaderDownloadJob, eachCallback

  , callback


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
    uidBatchLength: uidBatch.length

  GoogleUserModel.findById googleUserId, (error, googleUser) ->
    if error then callback winston.makeMongoError error; return

    unless googleUser then callback winston.makeError 'googleUser not found', {googleUserId: googleUserId}; return

    mailDownloadHelpers.downloadHeaders userId, googleUser, uidBatch, callback


exports.downloadHeaders = (userId, googleUser, uidBatch, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless uidBatch then callback winston.makeMissingParamError 'uidBatch'; return

  #TODO: write this...

  callback()