async = require 'async'
https = require 'https'

winston = require('./winstonWrapper').winston
LIUserModel = require('../schema/liUser').LIUserModel
contactHelpers = require './contactHelpers'
webUtils = require './webUtils'
urlUtils = require './urlUtils'

conf = require '../conf'
constants = require '../constants'

liHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  liHelpers.getUserJSONFromProfileData profile?._json

exports.getUserJSONFromConnection = (connection) ->
  liHelpers.getUserJSONFromProfileData connection

exports.getUserJSONFromProfileData = (profileData) ->
  profileData = profileData || {}
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
    
    liHelpers.getConnections userId, liUser, callback

exports.getConnections = (userId, liUser, callback) ->
  unless userId then callback winston.doMissingParamError 'userId'; return
  unless liUser then callback winston.doMissingParamError 'liUser'; return

  path = 'people/id=' + liUser._id + '/connections'
  liHelpers.doAPIGet liUser, path, (error, responseData) ->
    if error then callback error; return

    connections = responseData?.values
    unless connections then callback(); return

    # async.eachSeries is slower but helps solve a document versioning problem I encountered.
      # Google "versionerror: mongoose no matching document found" for more info.
      # There's probably a better solution using better error handling
      #   especially since this doesn't even guarantee safety with multiple workers.
    async.eachSeries connections, (connection, eachSeriesCallback) ->
      connectionLIUser = new LIUserModel liHelpers.getUserJSONFromConnection connection

      #Some connections are private.  Skip them.
      if connectionLIUser._id is 'private'
        eachSeriesCallback()
        return

      connectionLIUser.save (mongoError) ->
        if mongoError and mongoError.code isnt constants.MONGO_ERROR_CODE_DUPLICATE
          eachSeriesCallback winston.makeMongoError mongoError
          return

        contactHelpers.addContact userId, constants.service.LINKED_IN, connectionLIUser, eachSeriesCallback

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