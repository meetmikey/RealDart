async = require 'async'

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
  unless queueName then callback winston.makeMissingParamError 'queueName'; return
  unless job then callback winston.makeMissingParamError 'job'; return

  sqsUtils._addMessageToQueue queueName, job, callback


# maxWorkersInput and workerTimeout are optional and use defaults if not specified.
exports.pollQueue = ( queueName, handleMessage, maxWorkersInput, workerTimeout ) ->
  unless queueName then winston.doMissingParamError 'queueName'; return
  unless handleMessage then winston.doMissingParamError 'handleMessage'; return

  queueInfo = sqsUtils._getQueueInfo queueName
  
  maxWorkers = constants.sqs.DEFAULT_MAX_WORKERS_PER_QUEUE
  if maxWorkersInput
    maxWorkers = maxWorkersInput
  queueInfo.maxWorkers = maxWorkers

  if workerTimeout
    queueInfo.workerTimeout = workerTimeout

  sqsUtils._pollQueue queueName, handleMessage



# Public special control functions
# --------------------------------------

#This is called by appInitUtils.
# So for any app that will do worker jobs, just include the HANDLE_SQS_WORKERS initAction
exports.initWorkers = () ->
  sqsUtils._queueInfo = {}
  sqsUtils._stopSignalReceived = false
  sqsUtils._checkWorkersInterval = null

  for queueName of conf.queue
    queueInfo =
      stopWorkForQueueReceived: false
      workerInfos: {}
      numConsecutiveMisses: 0
      maxWorkers: 0 # Start with 0 by default until pollQueue is called with a new maxWorkers.
      workerTimeout: constants.sqs.DEFAULT_WORKER_TIMEOUT
    sqsUtils._queueInfo[queueName] = queueInfo

  sqsUtils._startCheckWorkers()

  process.on 'SIGUSR2', () ->
    sqsUtils._stopSignal()






# ALL PRIVATE BELOW HERE
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------


exports._stopSignal = () ->
  sqsUtils._stopSignalReceived = true
  conf.turnDebugModeOn()
  winston.doInfo 'SQS: Received stop signal'
  sqsUtils._checkStoppedAndDone()


exports._checkStoppedAndDone = () ->
  if sqsUtils._stopSignalReceived and sqsUtils._getNumTotalWorkers() is 0
    winston.doInfo constants.sqs.MESSAGE_ALL_WORKERS_DONE



# Private init and data functions
# --------------------------------------


exports._init = () ->
  sqsUtils._initAWS()
  

exports._initAWS = () ->
  sqsUtils._sqs = new AWS.SQS
    apiVersion: conf.aws.sqs.apiVersion



#  Private SQS/Queue functions
#  --------------------------------------


exports._startCheckWorkers = () ->
  sqsUtils._checkWorkersInterval = setInterval () ->

    if sqsUtils._stopSignalReceived and ( sqsUtils._getNumTotalWorkers() is 0 )
      if sqsUtils._checkWorkersInterval
        clearInterval sqsUtils._checkWorkersInterval
        sqsUtils._checkWorkersInterval = null
    else
      sqsUtils._checkWorkers()

  , constants.sqs.CHECK_WORKERS_INTERVAL


exports._getQueueURL = (queueName) ->
  unless queueName
    winston.doMissingParamError 'queueName'
    return ''
  url = 'https://' + conf.aws.sqs.host + '/' + conf.aws.accountId + '/' + conf.aws.sqs.queueNamePrefix + utils.capitalize queueName
  url


exports._pollQueue = ( queueName, handleMessage ) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return

  sqsUtils._workQueue queueName, handleMessage


exports._workQueue = (queueName, handleMessage) ->
  if not queueName then winston.doMissingParamError('queueName'); return
  if not handleMessage then winston.doMissingParamError('handleMessage'); return
  
  if sqsUtils._stopSignalReceived
    return

  sqsUtils._getMessagesFromQueue queueName, (error, sqsMessages) ->
    if error then winston.handleError error

    # Important to set the next timeout here, after we've received the messages.
    #  So we know whether it was a 'hit' or a 'miss.'
    waitTime = sqsUtils._getQueueWaitTime queueName
    setTimeout () ->
      sqsUtils._workQueue queueName, handleMessage
    , waitTime

    sqsUtils._handleMessages queueName, sqsMessages, handleMessage


exports._handleMessages = (queueName, sqsMessages, handleMessage) ->
  unless queueName then winston.doMissingParamError 'queueName'; return

  sqsMessages ||= []
  async.each sqsMessages, (sqsMessage, eachCallback) ->

    workerId = sqsUtils._addWorker queueName, sqsMessage

    messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage
    winston.doInfo 'got message from queue',
      queueName: queueName
      messageBodyJSON: messageBodyJSON

    handleMessage messageBodyJSON, (handleMessageError) ->

      sqsUtils._handleMessageDeletion queueName, sqsMessage, handleMessageError, (deletionError) ->
        if deletionError
          winston.handleError deletionError

        sqsUtils._deleteWorker queueName, workerId

        eachCallback()

  , () ->
    #winston.doInfo 'done handling messages'


exports._getMessagesFromQueue = ( queueName, callback ) ->
  utils.runWithRetries sqsUtils._getMessagesFromQueueNoRetry, constants.sqs.NUM_AWS_RETRIES, callback, queueName


exports._getMessagesFromQueueNoRetry = ( queueName, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return

  numAvailableWorkers = sqsUtils._getNumAvailableWorkers queueName
  unless numAvailableWorkers > 0
    #winston.doInfo 'no room to work!',
    #  queueName: queueName

    # Register a 'miss' so we'll wait a little bit before asking again.
    sqsUtils._registerQueueMiss queueName
    callback()
    return

  if numAvailableWorkers > constants.sqs.MAX_RECEIVE_MESSAGES
    numAvailableWorkers = constants.sqs.MAX_RECEIVE_MESSAGES

  receiveMessageParams =
    QueueUrl: sqsUtils._getQueueURL queueName
    AttributeNames: ['ApproximateReceiveCount']
    MaxNumberOfMessages: numAvailableWorkers

  sqsUtils._sqs.receiveMessage receiveMessageParams, ( sqsError, sqsResponse ) ->
    if sqsError and utils.isNonEmptyObject( sqsError ) and sqsError?.statusCode isnt 200
      winstonError = winston.makeError 'sqs error from ReceiveMessage',
        queueName: queueName
        sqsError: sqsError.toString()
      sqsUtils._registerQueueMiss queueName
      callback winstonError
      return

    sqsMessages = sqsResponse?.Messages || []
    unless sqsMessages and sqsMessages.length > 0
      # winston.doInfo 'empty response'
      sqsUtils._registerQueueMiss queueName
      callback null, sqsMessages
      return

    sqsUtils._registerQueueHit queueName
    callback null, sqsMessages
      

exports._getNumAvailableWorkers = (queueName) ->
  unless queueName then winston.doMissingParamError 'queueName'; return 0

  queueInfo = sqsUtils._getQueueInfo queueName

  numActiveWorkers = sqsUtils._getNumActiveWorkers queueName
  maxWorkers = queueInfo.maxWorkers
  numAvailableWorkers = maxWorkers - numActiveWorkers
  unless maxWorkers > 0 and numAvailableWorkers > 0
    return 0
  numAvailableWorkers


exports._getMessageBodyJSON = (sqsMessage) ->
  messageBodyString = sqsMessage?.Body
  unless messageBodyString then return null

  try
    messageBodyJSON = JSON.parse messageBodyString
  catch exception
    winston.doError 'sqs message body parse exception',
      exception: exception
    messageBodyJSON = null

  messageBodyJSON


exports._handleMessageDeletion = (queueName, sqsMessage, handleMessageError, callback) ->
  unless sqsMessage then callback(); return

  unless sqsUtils._shouldDeleteFromQueue handleMessageError
    # Call this so we can get a new message anyway despite the fact that
    # we have opted not to delete the message from the queue
    callback()
    return
  
  sqsUtils._deleteMessageFromQueue queueName, sqsMessage, callback


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


exports._getReceiveCount = (sqsMessage) ->
  unless sqsMessage then winston.doMissingParamError 'sqsMessage'; return 0

  receiveCountString = sqsMessage?.Attributes?.ApproximateReceiveCount  
  try
    receiveCount = parseInt receiveCountString, constants.RADIX_DECIMAL
  catch exception
    winston.doError 'exception parsing receiveCount int',
      receiveCountString: receiveCountString
    return 0
  receiveCount


exports._addMessageToQueue = ( queueName, messageBodyJSON, callback ) ->
  utils.runWithRetries sqsUtils._addMessageToQueueNoRetry, constants.sqs.NUM_AWS_RETRIES, callback, queueName, messageBodyJSON


exports._addMessageToQueueNoRetry = ( queueName, messageBodyJSON, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not messageBodyJSON then callback winston.makeMissingParamError('messageBodyJSON'); return

  sendMessageParams =
    MessageBody: JSON.stringify messageBodyJSON
    QueueUrl: sqsUtils._getQueueURL queueName

  sqsUtils._sqs.sendMessage sendMessageParams, ( sqsError, result ) ->

    winston.doInfo 'added message to queue',
      queueName: queueName
      messageBodyJSON: messageBodyJSON
      
    if callback
      winstonError = null
      if sqsError and utils.isNonEmptyObject( sqsError ) and sqsError?.statusCode isnt 200
        sqsErrorMessage = sqsError.toString()
        winstonError = winston.makeError 'sqs send message error',
          sqsError: sqsErrorMessage
          queueName: queueName
      callback winstonError, result


exports._deleteMessageFromQueue = ( queueName, sqsMessage, callback ) ->
  utils.runWithRetries sqsUtils._deleteMessageFromQueueNoRetry, constants.sqs.NUM_AWS_RETRIES, callback, queueName, sqsMessage


exports._deleteMessageFromQueueNoRetry = ( queueName, sqsMessage, callback ) ->
  if not queueName then callback winston.makeMissingParamError('queueName'); return
  if not sqsMessage then callback winston.makeMissingParamError('sqsMessage'); return
  
  receiptHandle = sqsMessage?.ReceiptHandle
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
    if sqsError and utils.isNonEmptyObject( sqsError ) and sqsError?.statusCode isnt 200
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


exports._getQueueInfo = (queueName) ->
  unless queueName then winston.doMissingParamError 'queueName'; return {}
  queueInfo = sqsUtils._queueInfo?[queueName]
  unless queueInfo then winston.doError 'no queueInfo', {queueName: queueName}; return {}
  queueInfo


exports._registerQueueMiss = (queueName) ->
  unless queueName then winston.doMissingParamError 'queueName'; return
  queueInfo = sqsUtils._getQueueInfo queueName
  queueInfo.numConsecutiveMisses++


exports._registerQueueHit = (queueName) ->
  unless queueName then winston.doMissingParamError 'queueName'; return
  queueInfo = sqsUtils._getQueueInfo queueName
  queueInfo.numConsecutiveMisses = 0


exports._getQueueWaitTime = ( queueName ) ->
  baseWait = constants.sqs.WAIT_TIME_BASE_MS
  queueInfo = sqsUtils._getQueueInfo queueName
  wait = baseWait
  numConsecutiveMisses = queueInfo.numConsecutiveMisses
  if numConsecutiveMisses
    wait = baseWait * Math.pow 2, ( numConsecutiveMisses - 1 )
  if wait > constants.sqs.MAX_WAIT_TIME_MS
    wait = constants.sqs.MAX_WAIT_TIME_MS
  wait



# Private worker functions
# -----------------------------------


exports._checkWorkers = () ->

  checkWorkersInfo = {}

  for queueName of conf.queue

    queueInfo = sqsUtils._getQueueInfo queueName
    workerInfos = queueInfo.workerInfos

    workerIdsToDelete = []
    for workerId, workerInfo of workerInfos
      elapsedTime = Date.now() - workerInfo.jobStartTime
      if elapsedTime > queueInfo.workerTimeout
        errorData =
          queueName: queueName
          workerId: workerId
          elapsedTime: elapsedTime
          workerTimeout: queueInfo.workerTimeout
          receiveCount: workerInfo.receiveCount
          messageBodyJSON: workerInfo.messageBodyJSON

        winston.doError 'worker timed out! deleting worker.', errorData
        sqsUtils._deleteWorker queueName, workerId

    numActiveWorkers = sqsUtils._getNumActiveWorkers queueName
    maxWorkers = queueInfo.maxWorkers

    checkWorkersInfo[queueName] = numActiveWorkers + '/' + maxWorkers

  winston.doInfo 'checkWorkers...(active/max)',
    checkWorkersInfo


exports._getNumActiveWorkers = (queueName) ->
  queueInfo = sqsUtils._getQueueInfo queueName
  numActiveWorkers = Object.keys( queueInfo.workerInfos ).length
  numActiveWorkers


exports._getNumTotalWorkers = () ->
  totalWorkers = 0
  for queueName of conf.queue
    numActiveWorkers = sqsUtils._getNumActiveWorkers queueName
    totalWorkers += numActiveWorkers
  totalWorkers


# Returns the workerId
exports._addWorker = (queueName, sqsMessage) ->
  unless queueName then winston.doMissingParamError 'queueName'; return
  unless sqsMessage then winston.doMissingParamError 'sqsMessage'; return

  messageBodyJSON = sqsUtils._getMessageBodyJSON sqsMessage
  receiveCount = sqsUtils._getReceiveCount sqsMessage

  queueInfo = sqsUtils._getQueueInfo queueName
  workerId = utils.getUniqueId()
  queueInfo.workerInfos[workerId] =
    messageBodyJSON: messageBodyJSON
    receiveCount: receiveCount
    jobStartTime: Date.now()
  workerId


exports._deleteWorker = (queueName, workerId) ->
  unless queueName then winston.doMissingParamError 'queueName'; return
  unless workerId then winston.doMissingParamError 'workerId'; return

  queueInfo = sqsUtils._getQueueInfo queueName
  delete queueInfo.workerInfos[workerId]

  sqsUtils._checkStoppedAndDone()



# Run _init
# --------------
sqsUtils._init()