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

    select =
      userId: userId
      googleUserId: googleUserId

    sort =
      _id: 1

    limit = commonConstants.ADD_EMAIL_TOUCHES_EMAIL_BATCH_SIZE
      
    EmailModel.find( select ).sort( sort ).limit( limit ).exec (mongoError, emails) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      emails ||= []
      async.each emails, (email, eachCallback) ->
        touchHelpers.addTouchesForEmail userId, googleUserId, email, eachCallback
      , callback