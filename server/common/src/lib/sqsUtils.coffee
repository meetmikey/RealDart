os = require 'os'

QueueFailModel = require('../schema/queueFail').QueueFailModel
winston = require('./winstonWrapper').winston
sesUtils = require './sesUtils'
AWS = require('./awsSDKWrapper').AWS
utils = require './utils'

constants = require '../constants'
conf = require '../conf'

sqsUtils = this



#  Public queue functions
#  --------------------------------------


exports.addJobToQueue = ( queueName, job, callback ) ->
  sqsUtils._addMessageToQueue queueName, job, callback


exports.pollQueue = ( queueName, handleMessage, maxWorkers, workerTimeout ) ->
  sqsUtils._pollQueue queueName, handleMessage, maxWorkers, workerTimeout



# Public special control functions
# --------------------------------------


exports.stopSignal = () ->
  sqsUtils._stopSignalReceived = true
  conf.turnDebugModeOn()
  winston.doInfo 'SQS: Received stop signal'
  if sqsUtils._getNumTotalWorkers() is 0
    winston.doInfo constants.message.SQS_ALL_WORKERS_DONE


exports.setStopSignalForQueue = (queueName, reason) ->
  if sqsUtils._stopWorkForQueueReceived[queueName] then return

  sqsUtils._stopWorkForQueueReceived[queueName] = true
  conf.turnDebugModeOn()
  winston.doInfo 'SQS: Received stop signal for queue',
    name: queueName
  msg = 'Stop signal for queue: ' + queueName + ' on host: ' + os.hostname()
  subject = queueName + ' on ' + os.hostname() + ' stopped work due to ' + reason

  sesUtils.sendInternalNotificationEmail msg, subject, (error) ->
    if error then winston.handlError error


#This is called by appInitUtils.
# So for any app that will do worker jobs, just include the HANDLE_SQS_WORKERS initAction
exports.initWorkers = () ->
  sqsUtils._workers = {}
  sqsUtils._checkWorkersIntervals = {}
  sqsUtils._stopSignalReceived = false
  sqsUtils._stopWorkForQueueReceived = {}

  for queueName of conf.queue
    sqsUtils._stopWorkForQueueReceived[queueName] = false
    sqsUtils._workers[queueName] = {}

  process.on 'SIGUSR2', () ->
    sqsUtils.stopSignal()


# ALL PRIVATE BELOW HERE
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------




# Private init and data functions
# --------------------------------------


exports._init = () ->
  sqsUtils._initAWS()
  

exports._initAWS = () ->
  sqsUtils._sqs = new AWS.SQS
    apiVersion: conf.aws.sqs.apiVersion


exports._getQueueURL = (queueName) ->
  unless queueName
    winston.doMissingParamError 'queueName'
    return ''
  url = 'https://' + conf.aws.sqs.host + '/' + conf.aws.accountId + '/' + conf.aws.sqs.queueNamePrefix + utils.capitalize queueName
  url


#  Private SQS/Queue functions
#  --------------------------------------


exports._pollQueue = ( queueName, handleMessage, maxWorkersInput, workerTimeoutInput ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  maxWorkers = 1
  if not maxWorkersInput
    winston.doWarn 'no maxWorkers specified, assuming 1!'
  else
    maxWorkers = maxWorkersInput

  sqsUtils._addNewWorkers maxWorkers, queueName, maxWorkers, handleMessage

  workerTimeout = constants.DEFAULT_WORKER_TIMEOUT
  if workerTimeoutInput
    workerTimeout = workerTimeoutInput

  if sqsUtils._checkWorkersIntervals[queueName]
    winston.doWarn 'sqsUtils: _pollQueue: existing _pollQueue interval for queue',
      queueName: queueName
  else
    sqsUtils._checkWorkersIntervals[queueName] = setInterval () ->
      if not ( sqsUtils._stopSignalReceived || sqsUtils._stopWorkForQueueReceived[queueName] ) || ( sqsUtils._getNumTotalWorkers() > 0 )
        sqsUtils._checkWorkers queueName, handleMessage, maxWorkers, workerTimeout
    , constants.CHECK_WORKERS_INTERVAL


exports._getMessageFromQueue = ( queueName, callback ) ->
  utils.runWithRetries sqsUtils._getMessageFromQueueNoRetry, constants.SQS_RETRIES, callback, queueName


exports._getMessageFromQueueNoRetry = ( queueName, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return

  receiveMessageParams =
    QueueUrl: sqsUtils._getQueueURL queueName
    AttributeNames: ['ApproximateReceiveCount']
    MaxNumberOfMessages: 1

  setTimeout () ->
    sqsUtils._sqs.receiveMessage receiveMessageParams, ( sqsError, sqsMessage ) ->
      if sqsError
        callback winston.makeError 'sqs error from ReceiveMessage',
          queueName: queueName
          sqsError: sqsError.toString()
        return

      # check approximate receive count - if over a certain threshold delete the message
      if sqsUtils._isTooManyDequeues sqsMessage
        sqsUtils._handleTooManyDequeues queueName, sqsMessage, callback
        return

      messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage
      callback null, messageBodyJSON, (handleMessageError, callback) ->
        sqsUtils._handleMessageDeletion queueName, sqsMessage, handleMessageError, callback
  , sqsUtils._getReceiveMessageTimeout queueName



exports._getReceiveMessageTimeout = (queueName) ->
  # TODO: back off here...
  return 0


exports._getMessageBodyJSON = (sqsMessage) ->
  messageBodyString = sqsUtils._getMessageFromSQSMessage( sqsMessage )?.Body
  unless messageBodyString then return null

  try
    messageBodyJSON = JSON.parse messageBodyString
  catch exception
    winston.doError 'sqs message body parse exception',
      exception: exception
    messageBodyJSON = null

  messageBodyJSON


exports._getMessageFromSQSMessage = (sqsMessage) ->
  unless sqsMessage?.Messages and sqsMessage.Messages.length > 0
    return null

  if sqsMessage.Messages.length > 1
    winston.doError 'too many sqs messages',
      sqsMessage: sqsMessage
    return null

  message = sqsMessage.Messages[0]
  message


exports._handleMessageDeletion = (queueName, sqsMessage, handleMessageError, callback) ->
  unless sqsMessage then callback(); return

  unless sqsUtils._shouldDeleteFromQueue handleMessageError
    # Call this so we can get a new message anyway despite the fact that
    # we have opted not to delete the message from the queue
    callback()
    return
  
  sqsUtils._deleteMessageFromQueue queueName, sqsMessage, callback


exports._handleTooManyDequeues = (queueName, sqsMessage, callback) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not sqsMessage then callback winston.makeMissingParamError('sqsMessage'); return
  
  messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage

  queueFail = new QueueFailModel
    queueName: queueName
    messageBody: JSON.stringify messageBodyJSON

  winston.doError 'Not processing and deleting queue message b/c it has been requeued too many times',
    sqsMessage: sqsMessage

  queueFail.save (mongoError) ->
    if mongoError then winston.doMongoError mongoError; callback(); return

    sqsUtils._deleteMessageFromQueue queueName, sqsMessage, () ->
      callback()


exports._shouldDeleteFromQueue = (error) ->
  unless error then return true

  # if this flag is set we want to suppress the error
  # from the logs (i.e. we dont want to handleError)
  unless winston.getSuppressErrorFlag error
    winston.handleError error

  # if this flag is set we can delete from queue despite
  # calling back with an error
  if winston.getDeleteFromQueueFlag error
    return true

  return false


exports._isTooManyDequeues = (sqsMessage) ->
  message = sqsUtils._getMessageFromSQSMessage sqsMessage
  receiveCountString = message?.Attributes?.ApproximateReceiveCount
  if receiveCountString is null then return false

  try
    receiveCount = parseInt receiveCountString, constants.RADIX_DECIMAL
  catch exception
    winston.doError 'exception parsing receiveCount int',
      receiveCountString: receiveCountString
    return false

  if receiveCount > constants.QUEUE_MAX_MESSAGE_RECEIVE_COUNT
    return true
  return false


exports._addMessageToQueue = ( queueName, messageBodyJSON, callback ) ->
  utils.runWithRetries sqsUtils._addMessageToQueueNoRetry, constants.SQS_RETRIES, callback, queueName, messageBodyJSON


exports._addMessageToQueueNoRetry = ( queueName, messageBodyJSON, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not messageBodyJSON then callback winston.makeMissingParamError('messageBodyJSON'); return

  sendMessageParams =
    MessageBody: JSON.stringify messageBodyJSON
    QueueUrl: sqsUtils._getQueueURL queueName

  winston.doInfo '_addMessageToQueueNoRetry, about to add message to queue',
    queueName: queueName
    messageBodyJSON: messageBodyJSON

  sqsUtils._sqs.sendMessage sendMessageParams, ( sqsError, result ) ->

    winston.doInfo 'added message to queue',
      queueName: queueName
      messageBodyJSON: messageBodyJSON
      
    if callback
      winstonError = null
      if sqsError
        sqsErrorMessage = sqsError.toString()
        winstonError = winston.makeError 'sqs send message error',
          sqsError: sqsErrorMessage
          queueName: queueName
      callback winstonError, result


exports._deleteMessageFromQueue = ( queueName, sqsMessage, callback ) ->
  utils.runWithRetries sqsUtils._deleteMessageFromQueueNoRetry, constants.SQS_RETRIES, callback, queueName, sqsMessage


exports._deleteMessageFromQueueNoRetry = ( queueName, sqsMessage, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not sqsMessage then callback winston.makeMissingParamError('sqsMessage'); return
  
  receiptHandle = sqsUtils._getMessageFromSQSMessage( sqsMessage )?.ReceiptHandle
  messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage

  unless receiptHandle
    winstonError = winston.makeError 'missing receipt handle',
      queueName: queueName
      messageBodyJSON: messageBodyJSON
    callback winstonError
    return

  deleteMessageParams =
    QueueUrl: sqsUtils._getQueueURL queueName
    ReceiptHandle: receiptHandle

  sqsUtils._sqs.deleteMessage deleteMessageParams, (sqsError) ->
    if sqsError
      winston.doError 'got error from DeleteMessage',
        sqsError: sqsError
        queueName: queueName
      callback()
    else
      messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage
      winston.doInfo 'deleted message from queue',
        queueName: queueName
        messageBodyJSON: messageBodyJSON
      callback()


exports._getSQSMessageAttribute = ( sqsMessage, attribute ) ->
  return sqsMessage?.ReceiveMessageResult?.Message?[attribute]



#  Private Worker functions
#  --------------------------------------

# A 'miss' is either an sqs error or 'no message'.
exports._workQueue = ( workerId, queueName, maxWorkers, handleMessage, previousConsecutiveMisses ) ->
  if not workerId then winston.doMissingParamError('workerId'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  #winston.doInfo 'working queue...',
  #  queueName: queueName

  if sqsUtils._stopSignalReceived or sqsUtils._stopWorkForQueueReceived[queueName]
    winston.doInfo 'Stopping worker',
      workerId: workerId
      queueName: queueName
    sqsUtils._deleteWorker queueName, workerId
    return

  else if not sqsUtils._isRoomToWork queueName, maxWorkers
    winston.doWarn 'No room to work!  Stopping.',
      queueName: queueName
      workerId: workerId
    return

  sqsUtils._updateWorkerLastContactTime workerId, queueName, maxWorkers, handleMessage, true
  hasCalledBack = false

  sqsUtils._getMessageFromQueue queueName, ( error, messageBodyJSON, messageCallback ) ->
    sqsUtils._updateWorkerLastContactTime workerId, queueName, maxWorkers, handleMessage
    if error
      winston.handleError error
      sqsUtils._reworkQueue workerId, queueName, maxWorkers, handleMessage, true, previousConsecutiveMisses
      return

    if not messageBodyJSON
      winston.doInfo 'empty message', {queueName: queueName}
      sqsUtils._reworkQueue workerId, queueName, maxWorkers, handleMessage, true, previousConsecutiveMisses
      return

    winston.doInfo 'got message from queue',
      queueName: queueName
      messageBodyJSON: messageBodyJSON

    sqsUtils._workers[queueName][workerId]['messageBodyJSON'] = messageBodyJSON
    handleMessage messageBodyJSON, (error) ->
      if sqsUtils._workers[queueName][workerId]
        sqsUtils._workers[queueName][workerId]['messageBodyJSON'] = null

      if not hasCalledBack
        messageCallback error, () ->
          sqsUtils._reworkQueue workerId, queueName, maxWorkers, handleMessage
        hasCalledBack = true
      else
        winston.doError 'Double callback to _workQueue handleMessage'


#A 'miss' is either an sqs error or 'no message'.
exports._reworkQueue = ( workerId, queueName, maxWorkers, handleMessage, isMiss, previousConsecutiveMisses ) ->
  if not workerId then winston.doMissingParamError('workerId'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  waitTime = 0
  newConsecutiveMisses = 0

  if isMiss
    #SQS sueues should be configured to long-poll, so requests/second should be minimal when there are no messages.
    #But just in case, let's back off if we're never getting any (with a limit).
    newConsecutiveMisses = 1
    if previousConsecutiveMisses
      newConsecutiveMisses = previousConsecutiveMisses + 1;
    waitTime = sqsUtils._getWorkQueueWaitTime newConsecutiveMisses

  setTimeout () ->
    sqsUtils._workQueue workerId, queueName, maxWorkers, handleMessage, newConsecutiveMisses, maxWorkers
  , waitTime


#consecutiveMisses should include the current miss.
exports._getWorkQueueWaitTime = ( consecutiveMisses ) ->
  baseWait = constants.QUEUE_WAIT_TIME_BASE
  wait = baseWait
  if consecutiveMisses
    wait = baseWait * Math.pow 2, ( consecutiveMisses - 1 )
  if wait > constants.QUEUE_MAX_WAIT_TIME
    wait = constants.QUEUE_MAX_WAIT_TIME
  wait


exports._checkWorkers = ( queueName, handleMessage, maxWorkers, workerTimeout ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not workerTimeout then winston.doMissingParamError('workerTimeout'); return

  if not sqsUtils._workers[queueName]
    winston.doError 'No worker queue!',
      queueName: queueName

  else
    numWorkersAlive = 0
    numWorkersOnJobs = 0
    for workerId, workerInfo of sqsUtils._workers[queueName]
      workerInfo = sqsUtils._workers[queueName][workerId]

      lastContactTime = workerInfo['lastContactTime']
      elapsedTime = Date.now() - lastContactTime
      messageBodyJSON = workerInfo['messageBodyJSON']

      if utils.isNonEmptyObject messageBodyJSON
        numWorkersOnJobs++

      if elapsedTime > workerTimeout
        errorData =
          queueName: queueName
          workerId: workerId
          elapsedTime: elapsedTime
          workerTimeout: workerTimeout
          messageBodyJSON: messageBodyJSON

        winston.doError 'worker timed out! deleting worker.', errorData
        sqsUtils._deleteWorker queueName, workerId

      else
        numWorkersAlive++

    winston.doInfo '_checkWorkers',
      queueName: queueName
      numWorkersAlive: numWorkersAlive
      numWorkersOnJobs: numWorkersOnJobs

    if not ( sqsUtils._stopSignalReceived or sqsUtils._stopWorkForQueueReceived[queueName] ) and ( numWorkersAlive < maxWorkers )
      newWorkersNeeded = maxWorkers - numWorkersAlive
      sqsUtils._addNewWorkers newWorkersNeeded, queueName, maxWorkers, handleMessage


exports._addNewWorkers = ( numWorkers, queueName, maxWorkers, handleMessage ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  if ( not numWorkers ) or ( not ( numWorkers > 0 ) )
    winston.doWarn 'sqsUtils: _addNewWorkers: no numWorkers specified, not adding any',
      queueName: queueName

  else
    for [0...numWorkers]
      sqsUtils._addNewWorker queueName, maxWorkers, handleMessage


exports._addNewWorker = ( queueName, maxWorkers, handleMessage ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  workerId = utils.getUniqueId()
  sqsUtils._addWorker workerId, queueName, maxWorkers, handleMessage


exports._addWorker = ( workerId, queueName, maxWorkers, handleMessage ) ->
  if not workerId then winston.doMissingParamError('workerId'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return
  
  winston.doInfo 'Starting queue worker...',
    queueName: queueName
    workerId: workerId

  if not sqsUtils._workers[queueName]
    winston.doMissingParamError 'workers[queueName]',
      queueName: queueName
    return

  workerInfo =
    lastContactTime: Date.now()

  sqsUtils._workers[queueName][workerId] = workerInfo
  setTimeout () ->
    sqsUtils._workQueue workerId, queueName, maxWorkers, handleMessage
  , 0


exports._deleteWorker = ( queueName, workerId ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not workerId then winston.doMissingParamError('workerId'); return

  delete sqsUtils._workers[queueName][workerId]

  if ( sqsUtils._stopSignalReceived or sqsUtils._stopWorkForQueueReceived[queueName] ) and ( sqsUtils._getNumTotalWorkers() is 0 )
    if sqsUtils._checkWorkersIntervals[queueName]
      clearInterval sqsUtils._checkWorkersIntervals[queueName]
      delete sqsUtils._checkWorkersIntervals[queueName]
    winston.doInfo constants.message.SQS_ALL_WORKERS_DONE


#Assumes that the caller is already working, so he is included in the current count of workers.
exports._isRoomToWork = ( queueName, maxWorkers ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return

  if not sqsUtils._workers[queueName]
    winston.doError 'no queue!',
      queueName: queueName

  else
    numWorkersOnQueue = sqsUtils._getNumWorkersOnQueue queueName
    if not numWorkersOnQueue > 0
      winston.doWarn 'No workers on queue!  Should be at least 1 since it includes ourselves.',
        queueName: queueName

    else
      #Subtract 1 to allow for ourselves (the caller)
      numOtherWorkers = numWorkersOnQueue - 1
      if numOtherWorkers < maxWorkers
        return true
      
  return false


exports._getNumWorkersOnQueue = ( queueName ) ->
  if not queueName then winston.doMissingParamError('queueName'); return 0

  numWorkersOnQueue = Object.keys( sqsUtils._workers[queueName] ).length
  numWorkersOnQueue


exports._getNumTotalWorkers = () ->
  totalWorkers = 0
  for queueName of sqsUtils._workers
    totalWorkers += sqsUtils._getNumWorkersOnQueue queueName
  totalWorkers


exports._updateWorkerLastContactTime = ( workerId, queueName, maxWorkers, handleMessage, addIfMissing ) ->
  if not workerId then winston.doMissingParamError('workerId'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  numWorkersOnQueue = sqsUtils._getNumWorkersOnQueue queueName
  if not numWorkersOnQueue > 0
    winston.doError 'No workers for queue!',
      queueName: queueName
      workerId: workerId

  else if not sqsUtils._workers[queueName][workerId]
    if addIfMissing
      winston.doWarn 'Worker not found! Re-adding worker.',
        queueName: queueName
        workerId: workerId
      sqsUtils._addWorker workerId, queueName, maxWorkers, handleMessage

  else
    sqsUtils._workers[queueName][workerId]['lastContactTime'] = Date.now()

sqsUtils._init()