async = require 'async'

winston = require('../lib/winstonWrapper').winston
GoogleUserModel = require('../schema/googleUser').GoogleUserModel
urlUtils = require './urlUtils'
contactHelpers = require './contactHelpers'

conf = require '../conf'
constants = require '../constants'

googleHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  userJSON = {}
  omitKeys = [
  ]
  for key, value of profile
    if omitKeys.indexOf( key ) isnt -1
      continue
      
    if key is 'id'
      userJSON['_id'] = value
    else if key is 'emails'
      emails = []
      for emailObject in value
        email = emailObject['value']
        emails.push email
      userJSON[key] = emails
    else
      userJSON[key] = value
  userJSON

exports.getContactsJSONFromAPIData = (contactsAPIData) ->
  unless apiData then return {}

  contacts = {}
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
        contact.emails.push email

    #email is critical here, so only allow contacts with primaryEmail
    if contact.primaryEmail
      contacts.push contact

  contacts


###
{
  "id":{
     "$t":"http://www.google.com/m8/feeds/contacts/justin%40mikeyteam.com/base/7c9bbb409153a40"
  },
  "updated":{
     "$t":"2013-05-10T17:35:45.749Z"
  },
  "category":[
     {
        "scheme":"http://schemas.google.com/g/2005#kind",
        "term":"http://schemas.google.com/contact/2008#contact"
     }
  ],
  "title":{
     "type":"text",
     "$t":"Andrew Lockhart"
  },
  "link":[
     {
        "rel":"http://schemas.google.com/contacts/2008/rel#edit-photo",
        "type":"image/*",
        "href":"https://www.google.com/m8/feeds/photos/media/justin%40mikeyteam.com/7c9bbb409153a40/1B2M2Y8AsgTpgAmY7PhCfg"
     },
     {
        "rel":"self",
        "type":"application/atom+xml",
        "href":"https://www.google.com/m8/feeds/contacts/justin%40mikeyteam.com/full/7c9bbb409153a40"
     },
     {
        "rel":"edit",
        "type":"application/atom+xml",
        "href":"https://www.google.com/m8/feeds/contacts/justin%40mikeyteam.com/full/7c9bbb409153a40/1368207345749001"
     }
  ],
  "gd$email":[
     {
        "rel":"http://schemas.google.com/g/2005#other",
        "address":"andrew@mikeyteam.com",
        "primary":"true"
     }
  ]
}
###

exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.googleUserId then callback winston.makeMissingParamError 'job.googleUserId'; return

  userId = job.userId
  googleUserId = job.googleUserId
  GoogleUserModel.findById googleUserId, (mongoError, googleUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    
    googleHelpers.getContacts userId, googleUser, callback


exports.getContacts = (userId, googleUser, callback) ->

  path = 'contacts/' + googleUser.email + '/full'
  #https://www.google.com/m8/feeds/contacts/justin@mikeyteam.com/full?access_token=<...>

  googleHelpers.doAPIGet googleUser, path, (error, apiResonseData) ->
    if error then callback error; return

    contactsData = googleHelpers.getContactsJSONFromAPIData apiResonseData?.feed?.entry

    async.each contactsData, (contactData, eachCallback) ->
      contactHelpers.addContact userId, constants.service.GOOGLE, contact, eachCallback
    , callback


exports.doAPIGet = (googleUser, path, callback) ->
  unless googleUser then callback winston.doMissingParamError 'googleUser'; return
  accessToken = liUser.accessToken
  unless accessToken then callback winston.doMissingParamError 'accessToken'; return
  unless path then callback winston.doMissingParamError 'path'; return

  data = 
    alt: 'json'
    access_token: accessToken

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