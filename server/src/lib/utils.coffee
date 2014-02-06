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
