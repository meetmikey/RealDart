_ = require 'underscore'

crypto = require 'crypto'
dateFormat = require 'dateformat'
constants = require '../constants'

winston = require('./winstonWrapper').winston
conf = require '../conf'

utils = this


exports.isArray = ( input ) ->
  if input is null or input is undefined
    return false
  if Object.prototype.toString.call( input ) is '[object Array]'
    return true
  return false


exports.isObject = ( input ) ->
  if input is null or input is undefined
    return false
  if Object.prototype.toString.call( input ) is '[object Object]'
    return true
  return false


exports.convertToInt = (strNumber) ->
  if typeof strNumber is 'string'
    number = Number strNumber
    if _.isNaN number
      return null
    return number
  
  if typeof strNumber is 'number'
    return strNumber
    
  return null


exports.capitalize = (input) ->
  unless input and ( input.length > 0 ) then return ''
  capitalized = input[0].toUpperCase() + input.slice 1
  capitalized


exports.uncapitalize = (input) ->
  unless input and ( input.length > 0 ) then return ''
  capitalized = input[0].toLowerCase() + input.slice 1
  capitalized


exports.isString = ( input ) ->
  return Object.prototype.toString.call( input ) == '[object String]'


#defaults to current date
exports.getDateString = (dateInput) ->
  dateValue = dateInput || new Date()
  dateString = dateFormat dateInput, constants.DATE_FORMAT
  dateString


exports.getRandomId = ( lengthInput ) ->
  rand = Math.random()
  date = Date.now()
  seedString = rand.toString() + date.toString()

  hash = utils.getHash seedString, 'md5'

  length = constants.DEFAULT_RANDOM_ID_LENGTH
  if lengthInput
    length = lengthInput

  hash = hash.substring 0, length
  hash


exports.getUniqueId = () ->
  uniqueId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random()*16|0
    if c is 'x'
      v = c = r
    else
      v = c = (r&0x3|0x8)
    uniqueId = v.toString 16
    uniqueId
  uniqueId


exports.getHash = (input, typeInput) ->
  unless input
    winston.doWarn 'utils: getHash: no input!'
    return ''

  type = 'md5'
  if typeInput
    type = typeInput

  validTypes = ['sha1', 'md5', 'sha256', 'sha512']
  if validTypes.indexOf( type ) is -1
    winston.doError 'utils: getHash: invalid hash type',
      type: type
    return ''

  cryptoHash = crypto.createHash type
  cryptoHash.update input
  hash = cryptoHash.digest 'hex'
  hash


exports.runWithRetries = ( func, numAttempts, callback, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 ) ->
  randomId = utils.getRandomId 4
  utils.runWithRetriesCountingFails func, numAttempts, callback, 0, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8


exports.runWithRetriesCountingFails = ( func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 ) ->
  if not func then callback winston.makeMissingParamError('func'); return
  if not numRemainingAttempts then callback winston.makeMissingParamError('numRemainingAttempts'); return

  numRemainingAttempts -= 1

  if typeof arg8 isnt 'undefined'
    func arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg7 isnt 'undefined'
    func arg1, arg2, arg3, arg4, arg5, arg6, arg7, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg6 isnt 'undefined'
    func arg1, arg2, arg3, arg4, arg5, arg6, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg5 isnt 'undefined'
    func arg1, arg2, arg3, arg4, arg5, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg4 isnt 'undefined'
    func arg1, arg2, arg3, arg4, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg3 isnt 'undefined'
    func arg1, arg2, arg3, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg2 isnt 'undefined'
    func arg1, arg2, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else if typeof arg1 isnt 'undefined'
    func arg1, ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8
  else
    func ( err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
      utils.runWithRetriesCallback func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8


exports.runWithRetriesCallback = ( func, numRemainingAttempts, callback, numPreviousFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6, cbArg7, cbArg8 ) ->
  if err and numRemainingAttempts >= 1
    
    numFails = numPreviousFails + 1
    winston.doWarn 'runWithRetries fail',
      randomId: randomId
      numRemainingAttempts: numRemainingAttempts
      numFails: numFails
      #arg1: arg1
      arg2: arg2
      arg3: arg3
    
    waitTime = utils.getRetryWaitTime numFails
    setTimeout () ->
      utils.runWithRetriesCountingFails func, numRemainingAttempts, callback, numFails, randomId, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
    , waitTime

  else if callback
    callback err, cbArg1, cbArg2, cbArg3, cbArg4, cbArg5, cbArg6


#returns the wait time in milliseconds, using exponential backoff with a max.
exports.getRetryWaitTime = ( numFails ) ->
  baseWait = constants.MIN_RETRY_WAIT_TIME_MS
  waitTime = baseWait

  if numFails
    waitTime = baseWait * Math.pow 2, ( numFails - 1 )

  if waitTime > constants.MAX_RETRY_WAIT_TIME_MS
    waitTime = constants.MAX_RETRY_WAIT_TIME_MS

  waitTime


# returns {encrypted: <encrypted value>, iv: <iv>}
exports.encryptSymmetric = (input) ->
  output =
    encrypted: null
    iv: null

  unless input
    #winston.doInfo 'utils.encryptSymmetric: input missing'
    return output

  iv = crypto.randomBytes(8).toString 'hex'
  cipher = crypto.createCipheriv conf.crypto.aes.scheme, conf.crypto.aes.secret, iv
  encrypted = cipher.update input, 'utf8', 'hex'
  encrypted += cipher.final 'hex'
  output.encrypted = encrypted
  output.iv = iv
  output


# returns the decrypted value
exports.decryptSymmetric = (input, iv) ->
  unless input 
    #winston.doInfo 'utils.decryptSymmetric: no input'
    return null
  iv = iv || ''

  decipher = crypto.createDecipheriv conf.crypto.aes.scheme, conf.crypto.aes.secret, iv
  decrypted = decipher.update input, 'hex', 'utf8'
  decrypted += decipher.final 'utf8'
  decrypted


# callback (err, buffer, isAborted)
exports.streamToBuffer = ( stream, capBuffer, callback ) ->
  unless stream then callback winston.makeMissingParamError 'stream'; return

  buffers = []
  hasCalledBack = false
  totalSize = 0

  stream.on 'data', (chunk) ->
    unless buffers
      if hasCalledBack
        winston.doWarn 'streamToBuffer error, buffer is null, but has already called back'
      else
        callback winston.makeError 'streamToBuffer error, buffer is null'
        hasCalledBack = true
      return

    buffers.push new Buffer( chunk, 'binary' )

    unless capBuffer
      return

    # cap the size of the response to avoid memory problems with large files...
    totalSize += chunk.length
    if totalSize > constants.MAX_STREAM_TO_BUFFER
      winston.doWarn 'streamToBuffer: MAX_STREAM_TO_BUFFER exceeded',
        size: totalSize
      buffer = Buffer.concat buffers
      buffers = null

      # last argument indicates that the buffer is truncated
      callback null, buffer, true
      hasCalledBack = true       

  stream.on 'end', () ->
    if hasCalledBack
      winston.doWarn 'streamToBuffer end, but has already called back'
      return

    buffer = null
    winstonError = null
    try
      buffer = Buffer.concat buffers
      buffers = null
    catch exception
      if exception.message is 'spawn ENOMEM'
        # TODO: this is catching the wrong thing, just error for now
        winston.doError 'spawn ENOMEM error'

      buffers = null
      winstonError = winston.makeError 'caught error concatenating buffer',
        message: exception.message
        stack: exception.stack

    if hasCalledBack
      winston.doWarn 'streamToBuffer has already called back'
      return

    hasCalledBack = true
    callback winstonError, buffer

  stream.on 'error', (err) ->
    if hasCalledBack
      winston.doWarn 'streamToBuffer error, but has already called back',
        err: err
      return

    buffers = null
    hasCalledBack = true
    callback winston.makeError 'streamToBuffer error',
        err: err


exports.removeNullFields = (object, removeEmptyStrings, removeEmptyArrays) ->
  unless object then return object

  for key, value of object
    
    if value is null
      object[key] = undefined
      delete object[key]
      continue

    if removeEmptyStrings and utils.isString value and value is ''
      object[key] = undefined
      delete object[key]
      continue

    if removeEmptyArrays and utils.isArray( value ) and ( value.length is 0 )
      object[key] = undefined
      delete object[key]
      continue

  object


exports.startsWithAPrefix = (input, prefixes) ->

  unless input
    return false
  
  inputLowerCase = input.toLowerCase()

  for prefix in prefixes
    prefixLowerCase = prefix.toLowerCase()
    if inputLowerCase.substring( 0, prefixLowerCase.length ) is prefixLowerCase
      return true

  return false