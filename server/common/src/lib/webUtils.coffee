http = require 'http'
https = require 'https'

utils = require './utils'
urlUtils = require './urlUtils'
winston = require('./winstonWrapper').winston
constants = require '../constants'

webUtils = this


# This is here as a convenience  since most of the time we'll want to use the
#  default number of redirects, but don't want to specify a "null" value in the params.
exports.webGet = ( url, asBuffer, callback ) ->
  #winston.doInfo 'webGet', {url : url}

  numArguments = arguments.length

  #Pass null, so we use the default
  webUtils.webGetWithRedirects url, asBuffer, null, callback

exports.webGetWithoutRedirects = ( url, asBuffer, callback ) ->
  #winston.doInfo 'webGetWithoutRedirects', {url: url}

  webUtils.webGetWithRedirects url, asBuffer, 0, callback


# numRedirectsToFollow is optional (can be passed as 'null' to use the default)
exports.webGetWithRedirects = ( url, asBuffer, numRedirectsToFollow, callback ) ->
  unless url then callback winston.makeMissingParamError 'url'; return

  #winston.doInfo 'webGetWithRedirects', {url : url}

  remainingRedirectsToFollow = constants.DEFAULT_NUM_REDIRECTS_TO_FOLLOW

  if ( numRedirectsToFollow is 0 ) or ( numRedirectsToFollow > 0 )
    remainingRedirectsToFollow = numRedirectsToFollow

  webUtils.webGetAttempt url, asBuffer, remainingRedirectsToFollow, url, callback


exports.webGetAttempt = ( url, asBuffer, remainingRedirectsToFollow, originalURL, callback ) ->
  unless url then callback winston.makeMissingParamError 'url'; return

  #winston.doInfo 'webGetAttempt', {url : url}

  # check protocol - only http, https can be processed
  unless urlUtils.hasValidProtocol url
    callback winston.makeRequestError 'invalid protocol',
      url: url
    return

  hasHandled = false

  if urlUtils.isHTTPS url

    parsedURL = urlUtils.parseURL url
    options =
      host: parsedURL.host
      port: 443
      path: parsedURL.path
      method: 'GET'

    try
      request = https.get options, ( response ) ->
        if hasHandled
          winston.doWarn 'double response from https get'
        else
          hasHandled = true
          exports.handleWebGetResponse response, asBuffer, remainingRedirectsToFollow, url, originalURL, request, callback
    catch exception
      callback winston.makeError 'caught error https get',
        stack: exception.stack
        message: exception.message
        url: url

  else  
    try
      request = http.get url, ( response ) ->
        if hasHandled
          winston.doWarn 'double response from http get'
        else
          hasHandled = true
          exports.handleWebGetResponse response, asBuffer, remainingRedirectsToFollow, url, originalURL, request, callback
    catch exception
      callback winston.makeError 'caught error http get',
        stack: e.stack
        message: e.message
        url: url

  if request
    request.on 'error', ( requestErr ) ->
      if hasHandled
        winston.doWarn 'error, but double response from http get',
          err: requestErr
      else
        hasHandled = true
        callback winston.makeRequestError requestErr

    request.setTimeout constants.DEFAULT_WEB_GET_TIMEOUT, () ->
      unless  hasHandled
        callback winston.makeError 'request timed out, aborting',
          url: url
        hasHandled = true
        request.abort()
        request = null

exports.handleWebGetResponse = ( response, asBuffer, remainingRedirectsToFollow, url, originalURL, request, callback ) ->

  unless response
    callback winston.makeError 'missing response',
      url: url
      originalURL: originalURL
    return

  responseCode = response.statusCode
  unless responseCode
    callback winston.makeError 'no response code',
      url: url
      originalURL: originalURL
    return

  if ( responseCode >= 300 ) and ( responseCode < 400 )

    if remainingRedirectsToFollow <= 0
      callback winston.makeError 'too many redirects',
        url: url
        originalURL: originalURL

    else if ( not response.headers ) or ( not response.headers.location )
      callback winston.makeError 'redirect code, but no location specified!'

    else
      redirectURL = response.headers.location
      remainingRedirectsToFollow = remainingRedirectsToFollow - 1
      ###
      winston.doInfo 'redirecting',
        originalURL: originalURL
        redirectURL: redirectURL
        remainingRedirectsToFollow: remainingRedirectsToFollow
      ###
      webUtils.webGetAttempt redirectURL, asBuffer, remainingRedirectsToFollow, originalURL, callback

    return

  if response.statusCode >= 400
    error = winston.makeError 'response error',
      responseCode: responseCode
      url: url
      originalURL: originalURL
    #winston.setSuppressErrorFlag error, true
    callback error
    return


  if webUtils.isWebResponseTooBig response
    winston.doWarn 'http webUtils response is too big, aborting'
    request.abort()
    callback null, '', url, response.headers, true
    return

  #we're good...
  if asBuffer
    utils.streamToBuffer response, true, (err, buffer, isAborted) ->
      if err then callback err; return

      if isAborted
        request.abort()
        callback null, buffer, url, response.headers, isAborted
        return

      callback null, buffer, url, response.headers

  else
    callback null, response, url, response.headers


exports.getPrintableResponseInfo = ( response, callback ) ->
 
  unless response
    winston.doWarn 'webUtils: getResponseInfo: no response'
    callback()
    return

  response.setEncoding 'utf8'
  hasCalledBack = false
  info = ''

  if response.headers
    info += 'HEADERS: ' + JSON.stringify response.headers

  response.on 'data', (chunk) ->
    if info
      info += ', '
    info += 'BODY CHUNK: ' + chunk

  response.on 'end', () ->
    if hasCalledBack
      winston.doWarn 'webUtils.getResponseInfo: already called back!'
    else
      hasCalledBack = true
      callback null, info

  setTimeout () ->
    unless hasCalledBack
      hasCalledBack = true
      winston.doWarn 'webUtils: getResponseInfo: never called back!'
      callback null, info
  , constants.RESPONSE_MAX_WAIT_MS

exports.isWebResponseTooBig = (response) ->
  if response?.headers?['content-length']
    length = utils.convertToInt response.headers['content-length']
    if length and ( length > constants.MAX_STREAM_TO_BUFFER )
      return true
  return false