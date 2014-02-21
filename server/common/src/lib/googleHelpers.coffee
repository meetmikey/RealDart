async = require 'async'

winston = require('../lib/winstonWrapper').winston
GoogleUserModel = require('../schema/googleUser').GoogleUserModel
GoogleContactModel = require('../schema/googleContact').GoogleContactModel
urlUtils = require './urlUtils'
mailUtils = require './mailUtils'
webUtils = require './webUtils'
sqsUtils = require './sqsUtils'
contactHelpers = require './contactHelpers'

conf = require '../conf'
constants = require '../constants'

googleHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  profileJSON = profile?._json || {}

  userJSON = {}
  omitKeys = [
  ]
  for key, value of profileJSON
    if omitKeys.indexOf( key ) isnt -1
      continue
      
    if key is 'id'
      userJSON['_id'] = value
    else
      userJSON[key] = value
  userJSON

exports.getContactsJSONFromAPIData = (contactsAPIData) ->
  unless contactsAPIData then return {}

  contacts = []
  for contactAPIData in contactsAPIData
    contact = {}
    
    title = contactAPIData?.title?['$t']
    if title
      contact.title = title

    parsedTitle = contactHelpers.parseFullName title
    contact.firstName = parsedTitle.firstName
    contact.middleName = parsedTitle.middleName
    contact.lastName = parsedTitle.lastName

    emailsData = contactAPIData?['gd$email']
    contact.emails = []
    if emailsData
      for emailData in emailsData
        emailAddress = emailData?.address
        unless emailAddress then continue
        if emailData?.primary is 'true'
          contact.primaryEmail = emailAddress
        contact.emails.push emailAddress

    #email is critical here, so only allow contacts with primaryEmail
    if contact.primaryEmail and mailUtils.isValidEmail contact.primaryEmail
      contacts.push contact

  contacts

exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return

  userId = job.userId
  googleUserId = job.googleUserId
  GoogleUserModel.findById googleUserId, (mongoError, googleUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless googleUser
      callback winston.makeError 'google user missing',
        googleUserId: googleUserId
      return

    googleHelpers.getContacts userId, googleUser, (error) ->
      if error then callback error; return

      mailDownloadJob =
        userId: userId
        googleUserId: googleUserId

      sqsUtils.addJobToQueue conf.queue.mailDownload, mailDownloadJob, callback


exports.getContacts = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  startIndex = 1
  path = 'contacts/' + googleUser.email + '/full'
  done = false

  async.whilst () ->
    not done
  , (whilstCallback) ->

    queryParams =
      'start-index': startIndex
      'max-results': conf.auth.google.maxContactResultsPerQuery

    googleHelpers.doAPIGet googleUser, path, queryParams, (error, apiResonseData) ->
      if error then whilstCallback error; return

      rawContactsFromResponse = apiResonseData?.feed?.entry

      contactsData = googleHelpers.getContactsJSONFromAPIData rawContactsFromResponse

      # async.eachSeries is slower but helps solve a document versioning problem I encountered.
      # Google "versionerror: mongoose no matching document found" for more info.
      # There's probably a better solution using better error handling
      #   especially since this doesn't even guarantee safety with multiple workers.
      async.eachSeries contactsData, (contactData, eachSeriesCallback) ->
        
        googleContact = new GoogleContactModel contactData
        googleContact.userId = userId
        googleContact.googleUserId = googleUser._id

        googleContact.save (mongoError) ->
          if mongoError and mongoError.code isnt constants.MONGO_ERROR_CODE_DUPLICATE
            eachSeriesCallback winston.makeMongoError mongoError
            return

          contactHelpers.addContact userId, constants.service.GOOGLE, googleContact, eachSeriesCallback

      , (error) ->
        if rawContactsFromResponse and rawContactsFromResponse.length
          startIndex += rawContactsFromResponse.length
        else
          done = true

        whilstCallback error

  , callback


exports.doAPIGet = (googleUser, path, extraData, callback) ->
  unless googleUser then callback winston.doMissingParamError 'googleUser'; return
  accessToken = googleUser.accessToken
  unless accessToken then callback winston.doMissingParamError 'accessToken'; return
  unless path then callback winston.doMissingParamError 'path'; return

  data = extraData || {}
  data.alt = 'json'
  data.access_token = accessToken

  queryString = urlUtils.getQueryStringFromData data
  url = 'https://www.google.com/m8/feeds'
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