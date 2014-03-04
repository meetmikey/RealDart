knox = require 'knox'
fs = require 'fs'
zlib = require 'zlib'

utils = require './utils'
urlUtils = require './urlUtils'
webUtils = require './webUtils'
winston = require('./winstonWrapper').winston

constants = require '../constants'
conf = require '../conf'

s3Utils = this


knoxClient = null
exports.getClient = () ->
  unless knoxClient
    knoxClient = knox.createClient
      key: conf.aws.key
      secret: conf.aws.secret
      bucket: conf.aws.s3.bucket
  knoxClient


exports.signedURL = (s3Path, filename, expireMinutesInput) ->
  unless s3Path then winston.doMissingParamError 's3Path'; return ''
  
  unless filename
    winston.doWarn 's3Utils.signedURL: no filename'
    filename = 'file'

  expireMinutes = constants.S3_DEFAULT_LINK_EXPIRE_MINUTES
  if expireMinutesInput
    expireMinutes = expireMinutesInput
  
  fullS3Path =  '' #conf.aws.s3.bucket
  unless s3Path.length and s3Path.substring(0, 1) is '/'
    fullS3Path += '/'
  fullS3Path += s3Path

  # note passing empty dictionary to knox client causes errors
  options =
    qs:
      'response-content-disposition': "inline; filename=\"" + filename + "\""
  expires = new Date()
  expires.setMinutes expires.getMinutes() + expireMinutes
  signedURL = s3Utils.getClient().signedUrl fullS3Path, expires, options
  signedURL


exports.getUploadHeadersFromResponse = (response) ->
  headers = {}
  unless response
    winston.doMissingParamError 'response'
  else
    headers['Content-Length'] = response.headers['content-length']
    headers['Content-Type'] = response.headers['content-type']
  headers


exports.putStream = (stream, s3Path, headers, useGzip, callback) ->
  unless stream then callback winston.makeMissingParamError 'stream'; return
  unless s3Path then callback winston.makeMissingParamError 's3Path'; return
  if useGzip then callback winston.makeError 's3Utils.putStream: useGzip not yet supported'; return

  winston.doInfo 's3Utils.putStream...',
    s3Path: s3Path
    headers: headers
    useGzip: useGzip
  
  hasCalledBack = false
  s3Utils.getClient().putStream stream, s3Path, headers, (s3Err, response) ->
    if hasCalledBack
      winston.doWarn 's3Utils.putStream: double callback',
        s3Err: s3Err
      return

    hasCalledBack = true
    s3Utils.checkS3Response s3Err, response,
      s3Path: s3Path
      request: 'putStream'
    , callback


exports.putBuffer = (buffer, s3Path, headers, useGzip, callback) ->
  unless buffer then callback winston.makeMissingParamError 'buffer'; return
  unless s3Path then callback winston.makeMissingParamError 's3Path'; return
  unless headers then callback winston.makeMissingParamError 'headers'; return

  if useGzip
    headers['Content-Encoding'] = 'gzip'
    zlib.gzip buffer, (zlibError, gzipBuffer) ->
      if zlibError then callback winston.makeError 'buffer zip failed', {s3Path: s3Path, zlibError: zlibError}; return

      s3Utils.putBuffer gzipBuffer, s3Path, headers, false, callback
    return

  startTime = Date.now()
  hasCalledBack = false
  s3Utils.getClient().putBuffer buffer, s3Path, headers, (s3Err, response) ->
    #Here lie 3 days of Justin's time and 2 days of Sagar's.  R.I.P.
    if hasCalledBack then winston.doWarn 's3Utils.putBuffer: double callback', {s3Err: s3Err}; return

    hasCalledBack = true
    s3Utils.checkS3Response s3Err, response,
      s3Path: s3Path
      request: 'putBuffer'
    , callback

    ###
    elapsedTime = Date.now() - startTime
    metric = 'bad'
    if elapsedTime
      metric = buffer.length / elapsedTime
    
    winston.doInfo 'completed putBuffer',
      s3Path: s3Path
      size: buffer.length
      elapsedTime: elapsedTime
      metric: metric
    ###      


exports.getFile = (s3Path, useGzip, callback) ->
  unless s3Path then callback winston.makeMissingParamError 's3Path'; return
  
  #winston.doInfo 's3Utils.getFile...',
  # s3Path : s3Path

  hasCalledBack = false
  s3Utils.getClient().getFile s3Path, (s3Err, response) ->
    if hasCalledBack then winston.doWarn 's3Utils.getFile: double callback', {s3Err: s3Err}; return

    hasCalledBack = true
    s3Utils.checkS3Response s3Err, response,
      s3Path: s3Path
      request: 'getFile'
    , (err) ->
      if err then callback err; return

      unless useGzip then callback null, response; return

      gunzip = zlib.createGunzip()
      response.pipe gunzip
      callback null, gunzip        


exports.deleteFile = (s3Path, callback) ->
  unless s3Path then callback winston.makeMissingParamError 's3Path'; return

  winston.doInfo 's3Utils: deleteFile...',
    s3Path: s3Path

  hasCalledBack = false
  s3Utils.getClient().deleteFile s3Path, (s3Err, res) ->
    if hasCalledBack then winston.doWarn 's3Utils.deleteFile: double callback', {s3Err: s3Err}; return

    hasCalledBack = true
    if s3Err then callback winston.makeS3Error s3Err; return

    callback()


exports.checkFileExists = (s3Path, callback) ->
  unless s3Path then callback winston.makeMissingParamError 's3Path'; return

  hasCalledBack = false
  s3Utils.getClient().headFile s3Path, (s3Err, res) ->
    if hasCalledBack then winston.doWarn 's3Utils.checkFileExists: double callback', {s3Err: s3Err}; return

    hasCalledBack = true
    if s3Err then callback winston.makeS3Error s3Err; return

    if res?.statusCode is 200
      callback null, true
    else
      callback null, false


exports.checkS3Response = (s3Error, response, logData, callback) ->
  unless utils.isObject logData
    logData = {}

  if s3Error then callback winston.makeS3Error s3Error, logData; return
  unless response then callback winston.makeError 'no response', logData; return

  if response?.statusCode is 200 then callback(); return
  
  webUtils.getPrintableResponseInfo response, (err, responseInfo) ->
    if err
      winston.doWarn 's3Utils.putBuffer: getPrintableResponseInfo error',
        err: err

    logData['statusCode'] = response.statusCode
    logData['responseInfo'] = responseInfo
    winstonError = winston.makeError 'non-200 status code', logData
    if response.statusCode.toString() is '404'
      winston.setErrorType winstonError, constants.errorType.web.FOUR_OH_FOUR
    callback winstonError