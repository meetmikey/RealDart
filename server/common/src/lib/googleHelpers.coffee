async = require 'async'
OAuth2 = require('oauth').OAuth2

winston = require('../lib/winstonWrapper').winston
GoogleUserModel = require('../schema/googleUser').GoogleUserModel
GoogleContactModel = require('../schema/googleContact').GoogleContactModel
urlUtils = require './urlUtils'
emailUtils = require './emailUtils'
webUtils = require './webUtils'
sqsUtils = require './sqsUtils'
utils = require './utils'
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
  for contactData in contactsAPIData
    newContact = {}
    
    title = contactData?.title?['$t']
    if title
      newContact.title = title

    googleHelpers.addName(newContact, contactData)
    googleHelpers.addEmails(newContact, contactData)
    googleHelpers.addPhoneNumbers(newContact, contactData)
    googleHelpers.addAddresses(newContact, contactData)
    googleHelpers.addBirthday(newContact, contactData)
    googleHelpers.addWebsites(newContact, contactData)
   
    #TODO: remove this check...
    #email is critical here, so only allow contacts with primaryEmail
    if newContact.primaryEmail and emailUtils.isValidEmail newContact.primaryEmail
      contacts.push newContact

  contacts


exports.addWebsites = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  websites = apiData['gContact$website']  
  if websites
    contact.websites = websites

exports.addAddresses = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  addressess = apiData['gd$structuredPostalAddress']
  if addressess
    contact.addressess = []
    for address in addressess
      newAddress = {}
      newAddress['formattedAddress'] = address?['gd$formattedAddress']?['$t']
      newAddress['city'] = address?['gd$formattedAddress']?['$t']
      newAddress['street'] = address?['gd$street']?['$t']
      newAddress['region'] = address?['gd$region']?['$t']
      newAddress['postcode'] = address?['gd$postcode']?['$t']
      contact.addressess.push(newAddress)


exports.addBirthday = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  birthday = apiData['gContact$birthday']
  if birthday
    contact.birthday = birthday.when

exports.addName = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  contactName = apiData['gd$name']
  contact.firstName = contactName?['gd$givenName']?['$t']
  contact.middleName = contactName?['gd$additionalName']?['$t']
  contact.lastName = contactName?['gd$familyName']?['$t']

exports.addEmails = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  emailsData = apiData['gd$email']
  contact.emails = []
  if emailsData
    for emailData in emailsData
      emailAddress = emailData?.address
      unless emailAddress then continue
      if emailData?.primary is 'true'
        contact.primaryEmail = emailAddress
      contact.emails.push emailAddress

exports.addPhoneNumbers = (contact, apiData) ->
  unless contact then callback winston,makeMissingParamError 'contact'; return;
  unless apiData then callback winston,makeMissingParamError 'apiData'; return;

  phoneNumbers = apiData['gd$phoneNumber']
  if phoneNumbers
    contact.phoneNumbers = []
    for number in phoneNumbers
      digits = number?['$t']
      relSplit = number?.rel?.split("#")
      type = relSplit[1] if relSplit.length > 0
      unless digits then continue
      contact.phoneNumbers.push {'number' : digits, 'type' : type}

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
  unless path then callback winston.doMissingParamError 'path'; return

  googleHelpers.getAccessToken googleUser, (error, accessToken) ->
    if error then callback error; return
    unless accessToken then callback winston.makeError 'no accessToken'; return

    data = extraData || {}
    data.v = '3.0'
    data.alt = 'json'
    data.access_token = accessToken

    queryString = urlUtils.getQueryStringFromData data
    url = 'https://www.google.com/m8/feeds'
    unless path.substring( 0, 1 ) is '/'
      url += '/'
    url += path + queryString

    winston.doInfo(url)

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


exports.getAccessToken = (googleUser, callback) ->
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  #winston.doInfo 'getAccessToken'

  timeBuffer = constants.gmail.ACCESS_TOKEN_UPDATE_TIME_BUFFER
  nowPlusBuffer = new Date(Date.now() + timeBuffer)
  
  accessToken = googleUser.accessToken
  accessTokenExpiresAt = googleUser.accessTokenExpiresAt
  refreshToken = googleUser.refreshToken

  # if there is a token and it's fresh just return it
  if accessToken and accessTokenExpiresAt and accessTokenExpiresAt > nowPlusBuffer
    #winston.doInfo 'access token still valid',
    #  accessTokenExpiresAt: accessTokenExpiresAt
    callback null, accessToken
    return

  unless refreshToken
    callback winston.makeError 'googleUser does not have a refreshToken or valid accessToken'
    return

  googleHelpers.getNewAccessTokenFromRefreshToken refreshToken, (error, accessToken, refreshToken, accessTokenExpiresAt) ->
    if error then callback error; return
    unless accessToken then callback winston.makeError 'no accessToken'; return
    unless accessTokenExpiresAt then callback winston.makeError 'no accessTokenExpiresAt'; return

    googleUser.accessToken = accessToken
    googleUser.accessTokenExpiresAt = accessTokenExpiresAt
    if refreshToken
      googleUser.refreshToken = refreshToken
    googleUser.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      callback null, accessToken


exports.getNewAccessTokenFromRefreshToken = (refreshToken, callback) ->
  unless refreshToken then callback winston.makeMissingParamError 'refreshToken'; return

  #winston.doInfo 'getting new accessToken'

  basePath = conf.auth.google.baseOAuthPath
  authorizePath = basePath + '/auth'
  accessTokenPath = basePath + '/token'

  oauth2 = new OAuth2 conf.auth.google.clientId, conf.auth.google.clientSecret, '', authorizePath, accessTokenPath
  oauth2.getOAuthAccessToken refreshToken,
    grant_type: 'refresh_token'
    refresh_token: refreshToken
  , (error, accessToken, refreshToken, results) ->
    if error
      callback winston.makeError 'error getting new google accessToken',
        errorStatusCode: error?.statusCode
        errorData: error?.data
      return

    unless accessToken and results?.expires_in
      callback winston.makeError 'missing accessToken or results.expires_in',
        accessToken: accessToken
        results: results
      return

    accessTokenExpiresAt = Date.now() + ( 1000 * results.expires_in )
    callback null, accessToken, refreshToken, accessTokenExpiresAt