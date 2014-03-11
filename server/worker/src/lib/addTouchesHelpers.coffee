commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'

EmailAccountStateModel = require(commonAppDir + '/schema/emailAccountState').EmailAccountStateModel
EmailModel = require(commonAppDir + '/schema/email').EmailModel
winston = require(commonAppDir + '/lib/winstonWrapper').winston
touchHelpers = require commonAppDir + '/lib/touchHelpers'

commonConstants = require commonAppDir + '/constants'

addTouchesHelpers = this


exports.doAddEmailTouchesJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return

  userId = job.userId
  unless userId then callback winston.makeError 'no userId', {job: job}; return
  googleUserId = job.googleUserId
  unless googleUserId then callback winston.makeError 'no googleUserId', {job: job}; return

  emailAccountStateSelect =
    userId: userId
    googleUserId: googleUserId

  EmailAccountStateModel.findOne emailAccountStateSelect, (mongoError, emailAccountState) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless emailAccountState
      winston.doError 'no emailAccountState', select
      callback()
      return

    highestEmailId = emailAccountState.highestEmailIdForAddingTouches
    isDone = false
    async.whilst () ->
      not isDone

    , (whilstCallback) ->
        addTouchesHelpers.addEmailTouchesBatch userId, googleUserId, highestEmailId, (error, isDoneFromBatch, newHighestEmailId) ->
          if error then whilstCallback error; return

          isDone = isDoneFromBatch
          highestEmailId = newHighestEmailId
          whilstCallback()

    , (error) ->
      if error then callback error; return

      addTouchesHelpers.updateEmailAccountStateHighestEmailId emailAccountState, highestEmailId, callback


exports.updateEmailAccountStateHighestEmailId = (emailAccountState, highestEmailId, callback) ->
  unless emailAccountState then callback winston.makeMissingParamError 'emailAccountState'; return

  unless emailAccountState.highestEmailIdForAddingTouches is highestEmailId
    callback()
    return

  emailAccountState.highestEmailIdForAddingTouches = highestEmailId
  emailAccountState.save (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    callback()


# callback is expected to pass (error, isDone, newHighestEmailId)
exports.addEmailTouchesBatch = (userId, googleUserId, highestEmailId, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUserId then callback winston.makeMissingParamError 'googleUserId'; return

  select =
    userId: userId
    googleUserId: googleUserId

  if highestEmailId
    select.emailId =
      $gt: highestEmailId

  sort =
    _id: 1

  limit = commonConstants.ADD_EMAIL_TOUCHES_EMAIL_BATCH_SIZE
    
  EmailModel.find( select ).sort( sort ).limit( limit ).exec (mongoError, emails) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    newHighestEmailId = highestEmailId
    emails ||= []
    isDone = true
    if emails.length >= limit
      isDone = false

    async.each emails, (email, eachCallback) ->

      if email._id > newHighestEmailId
        newHighestEmailId = email._id

      touchHelpers.addTouchesForEmail userId, googleUserId, email, eachCallback

    , (error) ->
        if error then callback error; return

        callback null, isDone, newHighestEmailId