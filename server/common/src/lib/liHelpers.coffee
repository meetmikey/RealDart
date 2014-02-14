commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'
https = require 'https'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
ContactModel = require(commonAppDir + '/schema/contact').ContactModel
webUtils = require './webUtils'
conf = require '../conf'

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

    async.each connections, (connection, eachCallback) ->
      connectionLIUser = new LIUserModel liHelpers.getUserJSONFromConnection connection
      
      connectionLIUser.save (mongoError) ->
        if mongoError then eachCallback winston.makeMongoError mongoError; return

        liHelpers.addContact userId, liUser, connectionLIUser._id, eachCallback

    , callback

exports.addContact = (userId, liUser, connectionId, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless liUser then callback winston.makeMissingParamError 'liUser'; return
  unless connectionId then callback winston.makeMissingParamError 'connectionId'; return

  contact = new ContactModel
    userId: userId
    liUserId: connectionId

  contact.save (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    callback()

exports.doAPIGet = (liUser, path, callback) ->
  unless liUser then callback winston.doMissingParamError 'liUser'; return
  accessToken = liUser.accessToken
  unless accessToken then callback winston.doMissingParamError 'accessToken'; return
  unless path then callback winston.doMissingParamError 'path'; return

  data = 
    format: 'json'
    oauth2_access_token: accessToken

  queryString = '?'
  first = true
  for key, value of data
    if not first
      queryString += '&'
    queryString += key + '=' + value
    first = false
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