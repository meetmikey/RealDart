async = require 'async'
https = require 'https'

winston = require('./winstonWrapper').winston
LIUserModel = require('../schema/liUser').LIUserModel
contactHelpers = require './contactHelpers'
webUtils = require './webUtils'
sqsUtils = require './sqsUtils'
urlUtils = require './urlUtils'
googleGeocoding = require './googleGeocoding'

conf = require '../conf'
constants = require '../constants'

liHelpers = this


exports.getUserJSONFromProfile = (profile) ->
  liHelpers.getUserJSONFromProfileData profile?._json


exports.getUserJSONFromConnection = (connection) ->
  liHelpers.getUserJSONFromProfileData connection


exports.getUserJSONFromProfileData = (profileData) ->
  profileData ||= {}
  userJSON = {}
  omitKeys = [
  ]
  for key, value of profileData
    if omitKeys.indexOf( key ) isnt -1
      continue
      
    if key is 'id'
      userJSON['_id'] = value
    else
      userJSON[key] = value
  userJSON


exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.liUserId then callback winston.makeMissingParamError 'job.liUserId'; return

  userId = job.userId
  liUserId = job.liUserId
  LIUserModel.findById job.liUserId, (mongoError, liUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    
    liHelpers.getConnections userId, liUser, (error) ->
      if error then callback error; return

      mergeContactsJob =
        userId: userId
      
      sqsUtils.addJobToQueue conf.queue.mergeContacts, mergeContactsJob, callback


exports.getConnections = (userId, liUser, callback) ->
  unless userId then callback winston.doMissingParamError 'userId'; return
  unless liUser then callback winston.doMissingParamError 'liUser'; return

  path = 'people/id=' + liUser._id + '/connections'
  liHelpers.doAPIGet liUser, path, (error, responseData) ->
    if error then callback error; return

    connections = responseData?.values
    unless connections then callback(); return

    async.each connections, (connection, eachCallback) ->
      connectionLIUser = new LIUserModel liHelpers.getUserJSONFromConnection connection

      #Some connections are private.  Skip them.
      if connectionLIUser._id is 'private'
        eachCallback()
        return

      connectionLIUser.save (mongoError) ->
        if mongoError and mongoError.code isnt constants.MONGO_ERROR_CODE_DUPLICATE
          eachCallback winston.makeMongoError mongoError
          return

        contactHelpers.addSourceContact userId, constants.contactSource.LINKED_IN, connectionLIUser, eachCallback

    , callback


exports.doAPIGet = (liUser, path, callback) ->
  unless liUser then callback winston.doMissingParamError 'liUser'; return
  accessToken = liUser.accessToken
  unless accessToken then callback winston.doMissingParamError 'accessToken'; return
  unless path then callback winston.doMissingParamError 'path'; return

  data = 
    format: 'json'
    oauth2_access_token: accessToken

  queryString = urlUtils.getQueryStringFromData data
  url = 'https://api.linkedin.com/v1'
  unless path.substring( 0, 1 ) is '/'
    url += '/'
  url += path + queryString

  webUtils.webGet url, true, (error, buffer) ->
    if error then callback error; return
    dataJSON = {}
    try
      dataJSON = JSON.parse buffer.toString()
    catch exception
      winston.doError 'response parse error',
        exceptionMessage: exception.message

    callback null, dataJSON

exports.getCurrentLocationFromLIUser = (liUser, callback) ->
  return callback winston.makeMissingParamError 'liUser' if not liUser
  location = {}
  location.country = liUser?.location?.country?.code
  location.readableLocation = liUser?.location?.name
  location.source = 'linkedin_location'

  #get the coordinates
  if location.readableLocation and location.country
    cleanLocation = liHelpers.cleanLocationNameForGeocoding location.readableLocation
    googleGeocoding.getGeocode cleanLocation, location.country, (err, geocode) ->
      return callback err if err

      location.lat = geocode.lat
      location.lng = geocode.lng
      callback null, location
  else
    callback null, location

exports.cleanLocationNameForGeocoding = (locationName) ->
  return unless locationName

  #hard code SF...
  if locationName == 'San Francisco Bay Area'
    locationName = 'San Francisco'

  locationName = locationName.replace(new RegExp('Area$'), '')
  locationName = locationName.replace(new RegExp('^Greater'), '')
  locationName.trim()