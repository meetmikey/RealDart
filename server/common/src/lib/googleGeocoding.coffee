conf = require '../conf'
constants = require '../constants'
winston = require('./winstonWrapper').winston
urlUtils = require('./urlUtils')
webUtils = require('./webUtils')
utils = require('./utils')

BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

googleGeocoding = this

exports.getGeocode = (city, state, callback) ->
  unless state then callback winston.makeMissingParamError 'state'; return
  unless city then callback winston.makeMissingParamError 'city'; return

  googleGeocoding.doAPIGet city, state, (err, data) ->
    return callback err if err
    geocode = googleGeocoding.getCoordinatesFromResponse(data)
    callback(null, geocode)

exports.doAPIGet = (city, state, callback) ->
  unless state then callback winston.makeMissingParamError 'state'; return
  unless city then callback winston.makeMissingParamError 'city'; return

  address = city + ', ' + state
  data =
    address : address
    componenets : 'country:US'
    key : conf.google_apis.key
    sensor : false

  queryString = urlUtils.getQueryStringFromData data
  url = BASE_URL + queryString

  utils.runWithRetries webUtils.webGet, constants.DEFAULT_API_CALL_ATTEMPTS
  , (error, buffer) ->
    if error then callback error; return
    dataJSON = {}
    try
      dataJSON = JSON.parse buffer.toString()
    catch exception
      winston.doError 'response parse error',
        exceptionMessage: exception.message

    callback null, dataJSON
  , url, true


exports.getCoordinatesFromResponse = (responseJSON) ->
  return unless responseJSON
  results = responseJSON.results

  #just take first result for now...
  if results and results.length
    topResult = results[0]
    geocode = topResult?.geometry?.location

    if geocode
      geocode['location_type'] = topResult?.geometry?.location_type

    geocode