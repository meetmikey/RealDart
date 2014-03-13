conf = require '../conf'
constants = require '../constants'
winston = require('./winstonWrapper').winston
urlUtils = require('./urlUtils')
webUtils = require('./webUtils')
utils = require('./utils')

BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

geocoding = this

exports.getGeocodeFromGoogle = (address, country, callback) ->
  unless address then callback winston.makeMissingParamError 'address'; return
  unless country then callback winston.makeMissingParamError 'country'; return

  geocoding.doGoogleAPIGet address, country, (err, data) ->
    return callback err if err
    geocode = geocoding.getCoordinatesFromGoogleResponse(data)
    callback(null, geocode)

exports.doGoogleAPIGet = (address, country, callback) ->
  unless address then callback winston.makeMissingParamError 'address'; return
  unless country then callback winston.makeMissingParamError 'country'; return

  data =
    address : address
    components : 'country:' + country
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


exports.getCoordinatesFromGoogleResponse = (responseJSON) ->
  return unless responseJSON
  results = responseJSON.results

  #just take first result for now...
  if results and results.length
    topResult = results[0]
    geocode = topResult?.geometry?.location

    if geocode
      geocode['locationType'] = topResult?.geometry?.location_type

    geocode


#database lookup since we already have cached the area code geocodes
exports.getGeocodeFromPhoneNumber = (phoneNumber, callback) ->

#database lookup since we already have cached the zip code geocodes
exports.getGeocodeFromZipCode = (zipCode, callback) ->
