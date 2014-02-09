crypto = require 'crypto'
dateFormat = require 'dateformat'
constants = require '../constants'

winston = require('./winstonWrapper').winston

utils = this

exports.isArray = ( input ) ->
  if input == null || input == undefined
    return false
  if Object.prototype.toString.call( input ) == '[object Array]'
    return true
  return false

exports.isObject = ( input ) ->
  if input == null || input == undefined
    return false
  if Object.prototype.toString.call( input ) == '[object Object]'
    return true
  return false

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