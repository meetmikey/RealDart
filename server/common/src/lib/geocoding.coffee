conf = require '../conf'
constants = require '../constants'
winston = require('./winstonWrapper').winston
urlUtils = require('./urlUtils')
webUtils = require('./webUtils')
utils = require('./utils')
AreaCodeModel = require('../schema/areaCode').AreaCodeModel
GeocodeCacheModel = require('../schema/location').GeocodeCacheModel

BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

geocoding = this

exports.getGeocodeFromGoogle = (address, country, callback) ->
  unless address then callback winston.makeMissingParamError 'address'; return
  unless country then callback winston.makeMissingParamError 'country'; return

  geocoding.doGoogleAPIGet address, country, (err, data) ->
    return callback err if err
    geocode = geocoding.getCoordinatesFromGoogleResponse(data)
    callback(null, geocode)

exports.cacheGeocodeResult = (address, country, geocodeResponse, callback) ->
  console.log geocodeResponse
  _id = JSON.stringify({address: address, country : country})
  response = JSON.stringify(geocodeResponse?.results)

  cacheModel = new GeocodeCacheModel {_id : _id, response : response}

  cacheModel.save (err) ->
    if err then callback winston.makeMongoError(err); return

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

      if dataJSON.status == 'OK'
        geocoding.cacheGeocodeResult address, country, dataJSON, (err) ->
          if err then winston.handleError err

          # as long as we have data, callback
          callback null, dataJSON
      else 
        callback winston.makeError 'google geocoding response not OK', {responseData : dataJSON}

    catch exception
      callback winston.makeError 'response parse error', exceptionMessage: exception.message
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
  areaCode = geocoding.getAreaCodeFromPhoneNumber(phoneNumber)
  if areaCode
    AreaCodeModel.findById areaCode, (err, areaCodeFromDB) ->
      if err
        callback(winston.makeMongoError(err))
      else if !areaCodeFromDB
        callback(winston.makeError 'area code not found in DB', {areaCode : areaCode})
      else
        location = {}
        location.lat =  areaCodeFromDB.lat
        location.lng = areaCodeFromDB.lng
        location.locationType = 'APPROXIMATE'
        location.city = areaCodeFromDB.majorCities[0]
        location.state = areaCodeFromDB.state
        location.readableAddress = areaCodeFromDB.majorCities[0] + ", " + areaCodeFromDB.state
        callback null, location
  else
    callback winston.makeError 'area code could not be parsed from phone number'

#returns undefined if phoneNumber cannot be parsed
exports.getAreaCodeFromPhoneNumber = (phoneNumber) ->
  if phoneNumber?.length == 7
    winston.doWarn 'getAreaCodeFromPhoneNumber: no area code present'
  else if phoneNumber?.length == 10
    phoneNumber.substring(0,3)
  else if phoneNumber?.length == 11 && phoneNumber.substring(0,1) == '1'
    phoneNumber.substring(1,4)