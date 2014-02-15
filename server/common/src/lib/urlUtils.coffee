libURL = require 'url'

utils = require './utils'
winston = require('./winstonWrapper').winston

constants = require '../constants'

urlUtils = this

exports.getHostname = ( url, keepWWW ) ->
  unless url then return ''

  parsedURL = urlUtils.parseURL url
  unless parsedURL then return ''

  hostname = parsedURL.hostname
  unless hostname then return ''

  wwwString = 'www.'
  if ( not keepWWW ) and ( hostname.indexOf( wwwString ) is 0 )
    hostname = hostname.substring wwwString.length

  hostname


exports.addProtocolIfMissing = (url) ->
  unless url then return ''

  url = url.trim()
  protocols = [
    'http://'
    'https://'
  ]
  hasProtocol = false
  for protocol in protocols
    if url.substring(0, protocol.length) is protocol
      hasProtocol = true
      break

  unless urlUtils.hasValidProtocol url
    url = 'http://' + url
  url


exports.hasValidProtocol = (url) ->
  unless url then return false

  validProtocols = [
    'http:'
    'https:'
  ]
  
  parsed = libURL.parse url
  if parsed?.protocol and ( validProtocols.indexOf( parsed.protocol ) isnt -1 )
    return true
  return false


exports.parseURL = (url) ->
  unless url then return ''
  
  parsed = libURL.parse url
  parsed


exports.isHTTPS = (url) ->
  unless url then return false

  if url.toLowerCase().indexOf('https://') is 0
    return true

  return false

exports.getQueryStringFromData = (data) ->
  unless data then return ''

  queryString = '?'
  first = true
  for key, value of data
    if not first
      queryString += '&'
    queryString += key + '=' + value
    first = false
  queryString