async = require 'async'

LockModel = require('../schema/lock').LockModel
winston = require('./winstonWrapper').winston

constants = require '../constants'

lockUtils = this

lockCount = {}


exports.acquireLock = (key, lockHolderInfo, callback) ->

  numFails = 0
  startTime = Date.now()

  doAndCheckAcquireLockAttempt = () ->
    lockUtils._acquireLockAttempt key, lockHolderInfo, (error, success) ->
      if error then callback error; return

      # Got the lock, and we're done.
      if success then callback null, success; return

      numFails++
      timeElapsed = Date.now() - startTime
      if timeElapsed > constants.lock.MAX_WAIT_TIME_MS
        callback()
        return

      newTimeout = constants.lock.BASE_WAIT_TIME_MS * Math.pow 2, ( numFails - 1 )
      setTimeout doAndCheckAcquireLockAttempt, newTimeout

  setTimeout doAndCheckAcquireLockAttempt, 0


exports._acquireLockAttempt = (key, lockHolderInfo, callback) ->

  select =
    key: key

  lockHolderInfo ||= {}
  lockHolderInfoString = JSON.stringify lockHolderInfo

  lock = new LockModel
    key: key
    lockHolderInfo: lockHolderInfoString
    createdAt: Date.now()

  lock.save (mongoError) ->
    if mongoError
      if mongoError.code is constants.MONGO_ERROR_CODE_DUPLICATE
        # This lock is already taken!  callback without the key to signal this.
        lockUtils.printLockInfo key
        callback()
      else
        callback winston.makeMongoError mongoError
      return

    # OK, we made the lock.  callback with the key to signal that we got it.
    if lockCount[key] is 0 or lockCount[key] > 0
      lockCount[key]++
    else
      lockCount[key] = 1
    callback null, true


exports.printLockInfo = (key) ->
  unless key then winston.doMissingParamError 'key'; return

  select =
    key: key

  LockModel.findOne select, (mongoError, lock) ->
    if mongoError then winston.doMongoError mongoError; return

    unless lock
      winston.doWarn 'printLockInfo: no lock',
        key: key
      return

    lockHolderInfo = {}
    try
      lockHolderInfo = JSON.parse lock.lockHolderInfo
    catch exception
      winston.doError 'exception parsing lockHolderInfo',
        lockHolderInfo: lock.lockHolderInfo
    winston.doInfo 'lock taken',
      key: key
      lockHolderInfo: lockHolderInfo


exports.releaseLock = (key, callback) ->

  select =
    key: key

  LockModel.findOneAndRemove select, (mongoError, removedLock) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if removedLock
      unless lockCount[key] and lockCount[key] > 0
        winston.doWarn 'released a lock, but invalid lock count',
          key: key
          lockCountForKey: lockCount[key]
      else
        lockCount[key]--
    #else
    #  winston.doInfo 'releaseLock returned, did nothing'

    callback()


exports.releaseAllProcessLocks = (callback) ->
  keys = Object.keys lockCount
  async.each keys, (key, eachCallback) ->
    unless lockCount[key] and lockCount[key] > 0
      eachCallback()
      return

    unless lockCount[key] is 1
      winston.doWarn 'unsupported multiple locks for key',
        key: key
        lockCountKey: lockCount[key]

    lockUtils.releaseLock key, eachCallback
  , callback
    