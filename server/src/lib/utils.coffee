crypto = require 'crypto'
dateFormat = require 'dateformat'
constants = require '../constants'

utils = this

exports.isArray = ( input ) ->
  if input == null || input == undefined
    return false;
  if Object.prototype.toString.call( input ) == '[object Array]'
    return true
  return false

exports.isObject = ( input ) ->
  if input == null || input == undefined
    return false
  if Object.prototype.toString.call( input ) == '[object Object]'
    return true
  return false

exports.isString = ( input ) ->
  return Object.prototype.toString.call( input ) == '[object String]'

#defaults to current date
exports.getDateString = (dateInput) ->
  dateValue = dateInput || new Date()
  dateString = dateFormat dateInput, constants.DATE_FORMAT
  dateString

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