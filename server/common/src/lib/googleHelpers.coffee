async = require 'async'
OAuth2 = require('oauth').OAuth2
_ = require 'underscore'
winston = require('../lib/winstonWrapper').winston
GoogleUserModel = require('../schema/googleUser').GoogleUserModel
GoogleContactModel = require('../schema/googleContact').GoogleContactModel
urlUtils = require './urlUtils'
emailUtils = require './emailUtils'
webUtils = require './webUtils'
sqsUtils = require './sqsUtils'
utils = require './utils'
contactHelpers = require './contactHelpers'
geocoding = require './geocoding'

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

    googleHelpers.addContactId(newContact, contactData)
    googleHelpers.addContactGroupIds(newContact, contactData)
    googleHelpers.addName(newContact, contactData)
    googleHelpers.addEmails(newContact, contactData)
    googleHelpers.addPhoneNumbers(newContact, contactData)
    googleHelpers.addAddresses(newContact, contactData)
    googleHelpers.addBirthday(newContact, contactData)
    googleHelpers.addWebsites(newContact, contactData)

    if (newContact.primaryEmail and emailUtils.isValidEmail newContact.primaryEmail) or newContact.phoneNumbers?.length
      contacts.push newContact

  contacts

exports.getGroupsJSONFromAPIData = (groupsAPIData) ->
  unless groupsAPIData then return {}

  groups = []
  for groupDatum in groupsAPIData
    systemGroupId = groupDatum?['gContact$systemGroup']?['id']
    _id = groupDatum.id?['$t']?.split("/base/")[1]
    title = groupDatum?['title']?['$t']
    groups.push {systemGroupId : systemGroupId, title : title, _id : _id}
  groups

exports.addContactId = (contact, apiData) ->
  return unless contact and apiData
  contact.contactId = apiData['id']?['$t']?.split("/base/")[1]

exports.addContactGroupIds = (contact, apiData) ->
  return unless contact and apiData
  groups = apiData['gContact$groupMembershipInfo']
  if groups
    contact.groupIds = []
    for group in groups
      newGroupId = group['href']?.split("/base/")[1]
      contact.groupIds.push(newGroupId)

exports.addWebsites = (contact, apiData) ->
  return unless contact and apiData

  websites = apiData['gContact$website']
  if websites && websites.length > 0
    contact.websites = websites

exports.addAddresses = (contact, apiData) ->
  return unless contact and apiData

  addresses = apiData['gd$structuredPostalAddress']
  if addresses and addresses.length > 0
    contact.addresses = []
    for address in addresses
      newAddress = {}
      newAddress['formattedAddress'] = address?['gd$formattedAddress']?['$t']?.replace(/\n/g, ' ')
      newAddress['street'] = address?['gd$street']?['$t']?.replace(/\n/g, ' ')
      newAddress['city'] = address?['gd$city']?['$t']
      newAddress['postcode'] = address?['gd$postcode']?['$t']
      contact.addresses.push(newAddress)

exports.addBirthday = (contact, apiData) ->
  return unless contact and apiData

  birthday = apiData['gContact$birthday']
  if birthday
    contact.birthday = birthday.when

exports.addName = (contact, apiData) ->
  return unless contact and apiData

  contactName = apiData['gd$name']
  contact.firstName = contactName?['gd$givenName']?['$t']
  contact.middleName = contactName?['gd$additionalName']?['$t']
  contact.lastName = contactName?['gd$familyName']?['$t']

exports.addEmails = (contact, apiData) ->
  return unless contact and apiData

  emailsData = apiData['gd$email']
  contact.emails = []
  if emailsData
    for emailData in emailsData
      emailAddress = emailData?.address
      unless emailAddress then continue
      if not emailUtils.isEmailContactBlacklisted(emailAddress)
        if emailData?.primary is 'true'
          contact.primaryEmail = emailAddress
        contact.emails.push emailAddress


exports.addPhoneNumbers = (contact, apiData) ->
  return unless contact and apiData

  phoneNumbers = apiData['gd$phoneNumber']
  if phoneNumbers
    contact.phoneNumbers = []
    for number in phoneNumbers
      digits = number?['$t']
      relSplit = number?.rel?.split("#")
      type = relSplit[1] if relSplit.length > 0
      unless digits then continue
      contact.phoneNumbers.push {'number' : googleHelpers.cleanPhoneNumber(digits), 'type' : type}

exports.cleanPhoneNumber = (phoneNumber) ->
  phoneNumber.replace(/[-()\s]/g, '')

exports.addIsMyContact = (googleContact, googleUser) ->
  return unless googleContact and googleUser

  if googleUser and googleUser.contactGroups?.length
    myContactsGroup = _.find(googleUser.contactGroups, (group) -> group.systemGroupId == 'Contacts')
    myContactsGroupId = myContactsGroup?._id
    match = _.find(googleContact.groupIds, (groupId) -> myContactsGroupId == groupId)
    if match
      googleContact.isMyContact = true

exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return

  userId = job.userId
  googleUserId = job.googleUserId
  GoogleUserModel.findById googleUserId, (mongoError, googleUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    unless googleUser then callback winston.makeError 'no googleUser', {googleUserId: googleUserId}; return

    googleHelpers.getContactGroups userId, googleUser, (error, groupsData) ->
      if error then callback error; return

      #add the contact groups to the user
      googleUser.contactGroups = groupsData
      googleUser.save (error) ->
        if error then callback winston.makeMongoError(error); return

        googleHelpers.getContacts userId, googleUser, (error) ->

          winston.doInfo 'getContacts finished',
            error: error

          if error then callback error; return

          mailDownloadJob =
            userId: userId
            googleUserId: googleUserId

          sqsUtils.addJobToQueue conf.queue.mailDownload, mailDownloadJob, (error) ->
            if error then callback error; return
            
            mergeContactsJob =
              userId: userId
            
            sqsUtils.addJobToQueue conf.queue.mergeContacts, mergeContactsJob, callback


exports.getContactGroups = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  path = '/groups/' + googleUser.email + '/full'
  googleHelpers.doAPIGet googleUser, path, {}, (error, apiResponseData) ->
    return callback error if error

    callback null, googleHelpers.getGroupsJSONFromAPIData apiResponseData?.feed?.entry


exports.getContacts = (userId, googleUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return

  startIndex = 1
  path = 'contacts/' + googleUser.email + '/full'
  isDone = false

  async.whilst () ->
    not isDone
  , (whilstCallback) ->
    queryParams =
      'start-index': startIndex
      'max-results': conf.auth.google.maxContactResultsPerQuery

    googleHelpers.doAPIGet googleUser, path, queryParams, (error, apiResonseData) ->
      if error then whilstCallback error; return

      rawContactsFromResponse = apiResonseData?.feed?.entry
      contactsData = googleHelpers.getContactsJSONFromAPIData rawContactsFromResponse

      # TODO: do this as an update?
      async.eachSeries contactsData, (contactData, eachCallback) ->
        googleContact = new GoogleContactModel contactData
        googleContact.userId = userId
        googleContact.googleUserId = googleUser._id

        googleHelpers.addIsMyContact(googleContact, googleUser)

        googleHelpers.addLocations googleContact, (err) ->
          if err then winston.handleError err

          # save the contact regardless if there was an error
          googleContact.save (mongoError, googleContactSaved) ->
            if mongoError and mongoError.code isnt constants.MONGO_ERROR_CODE_DUPLICATE
              eachCallback winston.makeMongoError mongoError
              return
            eachCallback()
            #TODO: need to make save to addSourceContact fault tolerant to restarts
            googleContact = googleContactSaved
            contactHelpers.addSourceContact userId, constants.contactSource.GOOGLE, googleContact, eachCallback

      , (error) ->
        if rawContactsFromResponse and rawContactsFromResponse.length
          startIndex += rawContactsFromResponse.length
        else
          isDone = true

        whilstCallback error

  , callback


exports.addLocations = (contact, callback) ->
  return winston.makeMissingParamError 'contact' unless contact

  #get geocodes in parallel
  async.parallel [
    (cb) ->
      if contact.phoneNumbers?.length
        async.each contact.phoneNumbers, (phoneNumber, eachCb) ->
          googleHelpers.getLocationFromGoogleUserPhone phoneNumber.number, (err, data) ->
            if err
              eachCb(err)
            else
              phoneNumber.location = [data]
              eachCb()
        , (err) ->
          cb(err)
      else
        cb()
    (cb) ->
      if contact.addresses?.length
        async.each contact.addresses, (address, eachCb) ->
          googleHelpers.getLocationFromGoogleUserAddress address, (err, data) ->
            if err
              eachCb(err)
            else
              address.location = [data]
              eachCb()
        , (err) ->
          cb(err)
      else
        cb()
  ], (err) ->
    callback(err)

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

exports.getLocationFromGoogleUserAddress = (address, callback) ->
  unless address then callback winston.makeMissingParamError 'address'; return
  location = {}

  addressToQuery = googleHelpers.getAddressForQuery address
  return callback winston.makeError 'not enough info to get geocode' unless addressToQuery

  geocoding.getGeocodeFromGoogle addressToQuery, 'US', (err, geocode) ->
    return callback err if err

    if geocode
      location.lat = geocode.lat
      location.lng = geocode.lng
      location.locationType = geocode.locationType
      location.source = 'google_address'
    else
      winston.doWarn 'no geocode for address', addressToQuery

    callback null, location

exports.getAddressForQuery = (address) ->
  if address.formattedAddress
    return address.formattedAddress
  else if address.street and address.city and address.region
    return address.street + ', ' + address.city + ", " + address.region
  else if address.postcode
    return address.postcode
  else if address.city and address.region
    return address.city + ", " + address.region
  else if address.city
    return address.city
  else if address.region
    return address.region
  else
    return undefined

exports.getLocationFromGoogleUserPhone = (phone, callback) ->

  unless phone then callback winston.makeMissingParamError 'phone'; return
  location = {}

  geocoding.getGeocodeFromPhoneNumber phone, (err, geocode) ->
    return callback err if err

    location.lat = geocode.lat
    location.lng = geocode.lng
    location.locationType = geocode.locationType

    #copy - phone number won't have city, state, etc associated with it by default
    location.city = geocode.city
    location.state = geocode.state
    location.readableAddress = geocode.readableAddress
    location.source = 'google_phone'

    callback null, location
