winston = require 'winston'
conf = require '../conf'

environment = process.env.NODE_ENV;

#default options... expand later
winston.remove winston.transports.Console
winston.add winston.transports.Console,
  timestamp: true

winston.setErrorType = (winstonError, type) ->
  if not winstonError
    return

  if Object.prototype.toString.call( winstonError.extra ) isnt '[object Object]'
    winstonError.extra = {}

  winstonError.extra.errorType = type
  winstonError


# read into winstonError obj and get the type
winston.getErrorType = (winstonError) ->
  if not winstonError or not winstonError.extra
    return ''
  winstonError.extra.errorType


#doInfo, doWarn s
#----------------------------------
winston.doInfo = (log, extraInput, forceDisplay) ->
  extra = winston.fixExtra extraInput
  if conf.debugMode or forceDisplay
    winston.info log, extra

winston.doWarn = (log, extraInput) ->
  extra = winston.fixExtra extraInput
  winston.warn log, extra

#do*Error s
#----------------------------------

winston.doError = (log, extraInput, res) ->
  winston.handleError winston.makeError(log, extraInput, 3), res

winston.doResponseError = (res, log, responseCode, userMessage, extraInput) ->
  winston.handleError winston.makeResponseError(log, responseCode, userMessage, extraInput, 4), res

winston.doMongoError = (mongoErr, extraInput, res) ->
  winston.handleError winston.makeMongoError(mongoErr, extraInput, 5), res

winston.doMissingParamError = (paramName, extraInput, res) ->
  winston.handleError winston.makeMissingParamError(paramName, extraInput, 5), res

winston.doS3Error = (s3Err, extraInput, res) ->
  winston.handleError winston.makeS3Error(s3Err, extraInput, 5), res

winston.doElasticSearchError = (esErr, extraInput, res) ->
  winston.handleError winston.makeElasticSearchError(esErr, extraInput, 5), res

#make*Error s
#----------------------------------

winston.makeRequestError = (requestError, extraInput, skipStacktraceLinesInput) ->
  
  skipStacktraceLines = 4
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput
  
  extra = winston.mergeExtra extraInput,
    requestError: requestError.message

  error = winston.makeResponseError 'request error', 500, 'internal error', extra, skipStacktraceLines
  error

winston.makeMongoError = (mongoErrInput, extraInput, skipStacktraceLinesInput) ->
  skipStacktraceLines = 4
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput
  
  mongoErr = mongoErrInput
  if mongoErrInput and ( typeof mongoErrInput is 'object' )
    mongoErr = mongoErrInput.toString()

  extra = winston.mergeExtra extraInput,
    mongoErr: mongoErr

  error = winston.makeResponseError 'mongo error', 500, 'internal error', extra, skipStacktraceLines
  error

winston.makeS3Error = (s3Err, extraInput, skipStacktraceLinesInput) ->
  skipStacktraceLines = 4
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput

  newExtra = {}
  if s3Err
    newExtra['s3Err'] = s3Err.message

  extra = winston.mergeExtra extraInput, newExtra
  error = winston.makeResponseError 's3 error', 500, 'internal error', extra, skipStacktraceLines
  error


winston.makeElasticSearchError = (esErr, extraInput, skipStacktraceLinesInput) ->
  skipStacktraceLines = 4
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput

  esErrorString = ''
  if esErr
    esErrorString = esErr.toString()
  
  extra = winston.mergeExtra extraInput,
    esErr: esErrorString

  error = winston.makeResponseError 'elastic search error', 500, 'internal error', extra, skipStacktraceLines
  error


winston.makeMissingParamError = (paramName, extraInput, skipStacktraceLinesInput) ->
  skipStacktraceLines = 4
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput

  extra = winston.mergeExtra extraInput, {}
  error = winston.makeResponseError 'missing param: ' + paramName, 500, 'internal error', extra, skipStacktraceLines
  error

#Winston kind of sucks at handling non-string metadata in our 'extra' params.
winston.fixExtra = (extraInput) ->
  extra = {}
  for key, value of extraInput
    value = extraInput[key]
    value = winston.safeStringify( value )
    extra[key] = value
  extra

winston.safeStringify = (value) ->
  if value is null
    return '(null)'
  
  if typeof value is 'undefined'
    return '(undefined)'
  
  if typeof value is 'string'
    return value;
  
  if typeof value is 'object'
    cache = []
    value = JSON.stringify value, (key, value) ->
      if ( typeof value is 'object' ) and ( value isnt null )
        if cache.indexOf(value) isnt -1
          # Circular reference found, discard key
          return '(circular)'
        cache.push value
      value
    , "\t"
    cache = null
    return value

  if Array.isArray value
    value = value.toString()
    return value

  value = value.toString()
  return value


winston.addExtra = ( winstonError, newExtra ) ->
  winstonError.extra = winston.mergeExtra winstonError.extra, newExtra
  winstonError


winston.mergeExtra = (extraInput1, extraInput2) ->
  extra1 = extraInput1
  if ( extra1 is null ) || ( extra1 is undefined )
    extra1 = {}

  extra2 = extraInput2
  if ( extra2 is null ) || ( extra2 is undefined )
    extra2 = {}

  extra = {}
  for key, value of extra1
    extra[key] = extra1[key]

  for key, value of extra2
    extra[key] = extra2[key]

  extra


winston.makeError = (log, extraInput, skipStacktraceLinesInput) ->

  error = null
  if log
    skipStacktraceLines = 2
    if skipStacktraceLinesInput isnt undefined
      skipStacktraceLines = skipStacktraceLinesInput
    
    extra = winston.fixExtra extraInput
    extra.stacktrace = winston.stacktrace skipStacktraceLines

    error =
      log: log
      extra: extra

  error


winston.makeResponseError = (log, responseCode, userMessage, extra, skipStacktraceLinesInput) ->
  skipStacktraceLines = 3
  if skipStacktraceLinesInput isnt undefined
    skipStacktraceLines = skipStacktraceLinesInput

  error = winston.makeError log, extra, skipStacktraceLines

  if error  
    error.message = constants.DEFAULT_RESPONSE_MESSAGE
    error.code = constants.DEFAULT_RESPONSE_CODE

    if userMessage
      error.message = userMessage
    if responseCode
      error.code = responseCode

  error

#Note: Skips the first skipLinesInput of the stacktrace, defaults to 1 to skip itself
winston.stacktrace = (skipLinesInput) ->
  skipLines = 1
  if skipLinesInput isnt undefined
    skipLines = skipLinesInput
  
  try
    fullStacktrace  = new Error().stack
    lineBreak = '\n'
    split = fullStacktrace.split lineBreak
    stacktrace = fullStacktrace
    if split and ( split.length > ( skipLines + 1 ) )
      stacktrace = lineBreak
      for stacktraceLine in split
        if i > skipLines
          stacktrace += stacktraceLine + lineBreak

    return stacktrace

  catch exception
    message = '(stacktrace exception!)'
    if exception
      message += ' ' + exception.toString()
    return message

winston.handleError = (err, res) ->
  if err
    log = ''
    extra = {}
    if err.log
      log = err.log
    if err.extra
      extra = err.extra

    winston.error log, extra
    if res
      message = constants.DEFAULT_RESPONSE_MESSAGE
      if err.message
        message = err.message

      code = constants.DEFAULT_RESPONSE_CODE
      if err.code
        code = err.code

      res.send message, code

    return true

  return false


# clear visual indication of break in logs (used during restart)
winston.logBreak = () ->
  winston.consoleLog constants.LOG_BREAK
  winston.consoleError constants.LOG_BREAK

winston.consoleLog = console.log
winston.consoleError = console.error

exports.winston = winston
