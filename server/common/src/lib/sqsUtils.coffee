
aws = require 'aws-lib'
os = require 'os'
sesUtils = require './sesUtils'

winston = require('./winstonWrapper').winston
utils = require('./utils')

QueueFailModel = require('../schema/queueFail').QueueFailModel

constants = require '../constants'
conf = require '../conf'

sqsUtils = this



#  Public queue functions
#  --------------------------------------

exports.addJobToQueue = ( queueName, job, callback ) ->
  queue = sqsUtils._getQueue queueName
  unless queue then winston.doError 'missing queue', {queueName: queueName}; return
  sqsUtils._addMessageToQueue queue, queueName, job, 0, callback

exports.pollQueue = ( queueName, handleMessage, maxWorkers, workerTimeout ) ->
  queue = sqsUtils._getQueue queueName
  unless queue then winston.doError 'missing queue', {queueName: queueName}; return
  sqsUtils._pollQueue queue, queueName, handleMessage, maxWorkers, workerTimeout


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
  sqsUtils._initQueues()

exports._initQueues = () ->
  sqsUtils._queues = {}

  for queueName of conf.queue
    queuePath = '/' + conf.aws.accountId + '/' + conf.aws.sqs.queueNamePrefix + utils.capitalize queueName
    queueOptions =
      path: queuePath
    queue = aws.createSQSClient conf.aws.key, conf.aws.secret, queueOptions
    sqsUtils._queues[queueName] = queue

exports._getQueue = (queueName) ->
  sqsUtils._queues?[queueName]


#  Private SQS/Queue functions
#  --------------------------------------

exports._pollQueue = ( queue, queueName, handleMessage, maxWorkersInput, workerTimeoutInput ) ->

  if not queue then winston.doMissingParamError('queue'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  maxWorkers = 1
  if not maxWorkersInput
    winston.doWarn 'no maxWorkers specified, assuming 1!'
  else
    maxWorkers = maxWorkersInput

  sqsUtils._addNewWorkers maxWorkers, queue, queueName, maxWorkers, handleMessage

  workerTimeout = constants.DEFAULT_WORKER_TIMEOUT
  if workerTimeoutInput
    workerTimeout = workerTimeoutInput

  if sqsUtils._checkWorkersIntervals[queueName]
    winston.doWarn 'sqsUtils: _pollQueue: existing _pollQueue interval for queue',
      queueName: queueName
  else
    sqsUtils._checkWorkersIntervals[queueName] = setInterval () ->
      if not ( sqsUtils._stopSignalReceived || sqsUtils._stopWorkForQueueReceived[queueName] ) || ( sqsUtils._getNumTotalWorkers() > 0 )
        sqsUtils._checkWorkers queue, queueName, handleMessage, maxWorkers, workerTimeout
    , constants.CHECK_WORKERS_INTERVAL


exports._getMessageFromQueue = ( queue, queueName, callback ) ->
  utils.runWithRetries sqsUtils._getMessageFromQueueNoRetry, constants.SQS_RETRIES, callback, queue, queueName

exports._getMessageFromQueueNoRetry = ( queue, queueName, callback ) ->

  if not queue then callback winston.makeMissingParamError('queue'); return
  if not queueName then callback winston.makeMissingParamError('queueName'); return

  receiveMessageOptions =
    MaxNumberOfMessages: 1
    AttributeName: 'All'

  queue.call 'ReceiveMessage', receiveMessageOptions, ( sqsError, sqsMessage ) ->
    if sqsError
      callback winston.makeError 'sqs error from ReceiveMessage',
        queueName: queueName
        sqsError: sqsError.toString()
      return

    # check approximate receive count - if over a certain threshold delete the message
    if sqsUtils._isTooManyDequeues sqsMessage
      sqsUtils._handleTooManyDequeues queue, queueName, sqsMessage, callback
      return

    messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage
    callback null, messageBodyJSON, (handleMessageError, callback) ->
      sqsUtils._handleMessageDeletion queue, queueName, sqsMessage, handleMessageError, callback


exports._getMessageBodyJSON = (sqsMessage) ->
  messageBody = sqsUtils._getSQSMessageAttribute sqsMessage, 'Body'
  unless messageBody then return null

  try
    messageBodyJSON = JSON.parse messageBody
  catch exception
    winston.doError 'sqs message body parse exception',
      exception: exception
    messageBodyJSON = null

  messageBodyJSON


exports._handleMessageDeletion = (queue, queueName, sqsMessage, handleMessageError, callback) ->
  unless sqsMessage then callback(); return

  unless sqsUtils._shouldDeleteFromQueue handleMessageError
    # Call this so we can get a new message anyway despite the fact that
    # we have opted not to delete the message from the queue
    callback()
    return
    
  receiptHandle = sqsUtils._getSQSMessageAttribute sqsMessage, 'ReceiptHandle'
  unless receiptHandle
    return

  sqsUtils._deleteMessageFromQueue queue, queueName, sqsMessage, callback


exports._handleTooManyDequeues = (queue, queueName, sqsMessage, callback) ->

  if not queue then callback winston.makeMissingParamError('queue'); return
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

    sqsUtils._deleteMessageFromQueue queue, queueName, sqsMessage, () ->
      callback()

exports._shouldDeleteFromQueue = (error) ->
  unless error
    return true

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
  unless sqsMessage then return false

  attributeArray = sqsUtils._getSQSMessageAttribute sqsMessage, 'Attribute'

  if attributeArray
    for attribute in attributeArray
      if attribute.Name is 'ApproximateReceiveCount'
        receiveCount = parseInt attribute.Value, constants.RADIX_DECIMAL
        if receiveCount > constants.QUEUE_MAX_MESSAGE_RECEIVE_COUNT
          return true

  return false


exports._addMessageToQueue = ( queue, queueName, messageBodyJSON, delaySeconds, callback ) ->
  utils.runWithRetries sqsUtils._addMessageToQueueNoRetry, constants.SQS_RETRIES, callback, queue, queueName, messageBodyJSON, delaySeconds

exports._addMessageToQueueNoRetry = ( queue, queueName, messageBodyJSON, delaySeconds, callback ) ->
  if not queue then callback winston.makeMissingParamError('queue'); return
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not messageBodyJSON then callback winston.makeMissingParamError('messageBodyJSON'); return

  messageBody = JSON.stringify messageBodyJSON
  sqsMessage =
    MessageBody: messageBody

  if delaySeconds and delaySeconds > 0
    sqsMessage['DelaySeconds'] = delaySeconds

  queue.call 'SendMessage', sqsMessage, ( sqsError, result ) ->
    winston.doInfo 'Sent message to queue',
      messageBodyJSON: messageBodyJSON
    if callback
      winstonError = null
      if sqsError
        sqsErrorMessage = sqsError.toString()
        winstonError = winston.makeError 'sqs send message error',
          sqsError: sqsErrorMessage
          queueName: queueName
      callback winstonError, result

exports._deleteMessageFromQueue = ( queue, queueName, sqsMessage, callback ) ->
  utils.runWithRetries sqsUtils._deleteMessageFromQueueNoRetry, constants.SQS_RETRIES, callback, queue, queueName, sqsMessage

exports._deleteMessageFromQueueNoRetry = ( queue, queueName, sqsMessage, callback ) ->
  if not queue then callback winston.makeMissingParamError('queue'); return
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not sqsMessage then callback winston.makeMissingParamError('sqsMessage'); return
  
  receiptHandle = sqsUtils._getSQSMessageAttribute sqsMessage, 'ReceiptHandle'

  if not receiptHandle
    winston.doError 'missing receipt handle',
      sqsMessage: sqsMessage
      queueName: queueName
    return

  outbound =
    ReceiptHandle: receiptHandle

  winston.doInfo 'deleting message from queue',


  queue.call 'DeleteMessage', outbound, (sqsError) ->
    if sqsError
      winston.doError 'got error from DeleteMessage',
        sqsError: sqsError
        queueName: queueName
      callback()
    else
      message = sqsUtils._getSQSMessageAttribute sqsMessage, 'Body'
      winston.doInfo 'deleted message from queue',
        message: message
        queueName: queueName
      callback()

exports._getSQSMessageAttribute = ( sqsMessage, attribute ) ->
  return sqsMessage?.ReceiveMessageResult?.Message?[attribute]



#  Private Worker functions
#  --------------------------------------

# A 'miss' is either an sqs error or 'no message'.
exports._workQueue = ( workerId, queue, queueName, maxWorkers, handleMessage, previousConsecutiveMisses ) ->

  if not workerId then winston.doMissingParamError('workerId'); return
  if not queue then winston.doMissingParamError('queue'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  winston.doInfo 'working queue...',
    queueName: queueName

  if sqsUtils._stopSignalReceived or sqsUtils._stopWorkForQueueReceived[queueName]
    winston.doInfo 'Stopping worker',
      workerId: workerId
      queueName: queueName
    sqsUtils._deleteWorker queueName, workerId

  else if not sqsUtils._isRoomToWork queue, queueName, maxWorkers
    winston.doWarn 'No room to work!  Stopping.',
      queueName: queueName
      workerId: workerId

  else
    sqsUtils._updateWorkerLastContactTime workerId, queue, queueName, maxWorkers, handleMessage, true
    hasCalledBack = false

    sqsUtils._getMessageFromQueue queue, queueName, ( error, messageBodyJSON, messageCallback ) ->
      sqsUtils._updateWorkerLastContactTime workerId, queue, queueName, maxWorkers, handleMessage
      if error
        winston.handleError error
        sqsUtils._reworkQueue workerId, queue, queueName, maxWorkers, handleMessage, true, previousConsecutiveMisses

      else if not messageBodyJSON
        sqsUtils._reworkQueue workerId, queue, queueName, maxWorkers, handleMessage, true, previousConsecutiveMisses

      else
        sqsUtils._workers[queueName][workerId]['messageBodyJSON'] = messageBodyJSON
        handleMessage messageBodyJSON, (error) ->
          if sqsUtils._workers[queueName][workerId]
            sqsUtils._workers[queueName][workerId]['messageBodyJSON'] = null

          if not hasCalledBack
            messageCallback error, () ->
              sqsUtils._reworkQueue workerId, queue, queueName, maxWorkers, handleMessage
            hasCalledBack = true
          else
            winston.doError 'Double callback to _workQueue handleMessage'

#A 'miss' is either an sqs error or 'no message'.
exports._reworkQueue = ( workerId, queue, queueName, maxWorkers, handleMessage, isMiss, previousConsecutiveMisses ) ->

  if not workerId then winston.doMissingParamError('workerId'); return
  if not queue then winston.doMissingParamError('queue'); return
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
    sqsUtils._workQueue workerId, queue, queueName, maxWorkers, handleMessage, newConsecutiveMisses, maxWorkers
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

exports._checkWorkers = ( queue, queueName, handleMessage, maxWorkers, workerTimeout ) ->

  if not queue then winston.doMissingParamError('queue'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not workerTimeout then winston.doMissingParamError('workerTimeout'); return

  if not sqsUtils._workers[queueName]
    winston.doError 'No worker queue!',
      queueName: queueName

  else
    numWorkers = 0
    for workerId, workerInfo of sqsUtils._workers[queueName]
      workerInfo = sqsUtils._workers[queueName][workerId]

      lastContactTime = workerInfo['lastContactTime']
      elapsedTime = Date.now() - lastContactTime
      messageBodyJSON = workerInfo['messageBodyJSON']

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
        numWorkers++

    winston.doInfo '_checkWorkers',
      queueName: queueName
      numWorkers: numWorkers

    if not ( sqsUtils._stopSignalReceived or sqsUtils._stopWorkForQueueReceived[queueName] ) and ( numWorkers < maxWorkers )
      newWorkersNeeded = maxWorkers - numWorkers
      sqsUtils._addNewWorkers newWorkersNeeded, queue, queueName, maxWorkers, handleMessage

exports._addNewWorkers = ( numWorkers, queue, queueName, maxWorkers, handleMessage ) ->

  if not queue then winston.doMissingParamError('queue'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  if ( not numWorkers ) or ( not ( numWorkers > 0 ) )
    winston.doWarn 'sqsUtils: _addNewWorkers: no numWorkers specified, not adding any',
      queueName: queueName

  else
    for [0...numWorkers]
      sqsUtils._addNewWorker queue, queueName, maxWorkers, handleMessage

exports._addNewWorker = ( queue, queueName, maxWorkers, handleMessage ) ->

  if not queue then winston.doMissingParamError('queue'); return
  if not queueName then winston.doMissingParamError('queueName'); return
  if not maxWorkers then winston.doMissingParamError('maxWorkers'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  workerId = utils.getUniqueId()
  sqsUtils._addWorker workerId, queue, queueName, maxWorkers, handleMessage

exports._addWorker = ( workerId, queue, queueName, maxWorkers, handleMessage ) ->

  if not workerId then winston.doMissingParamError('workerId'); return
  if not queue then winston.doMissingParamError('queue'); return
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
    sqsUtils._workQueue workerId, queue, queueName, maxWorkers, handleMessage
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
exports._isRoomToWork = ( queue, queueName, maxWorkers ) ->

  if not queue then winston.doMissingParamError('queue'); return
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

exports._updateWorkerLastContactTime = ( workerId, queue, queueName, maxWorkers, handleMessage, addIfMissing ) ->
  
  if not workerId then winston.doMissingParamError('workerId'); return
  if not queue then winston.doMissingParamError('queue'); return
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
      sqsUtils._addWorker workerId, queue, queueName, maxWorkers, handleMessage

  else
    sqsUtils._workers[queueName][workerId]['lastContactTime'] = Date.now()

sqsUtils._init()