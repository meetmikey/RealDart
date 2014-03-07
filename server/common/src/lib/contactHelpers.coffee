async = require 'async'

fbHelpers = require './fbHelpers'
imageUtils = require './imageUtils'
ContactModel = require( '../schema/contact').ContactModel
SourceContactModel = require( '../schema/contact').SourceContactModel
TouchModel = require( '../schema/touch').TouchModel
winston = require('./winstonWrapper').winston
basicUtils = require './basicUtils'
emailUtils = require './emailUtils'
s3Utils = require './s3Utils'
sqsUtils = require './sqsUtils'
utils = require './utils'

constants = require '../constants'

contactHelpers = this


exports.addSourceContact = (userId, contactSource, contactData, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless contactSource then callback winston.makeMissingParamError 'contactSource'; return
  unless contactData then callback winston.makeMissingParamError 'contactData'; return

  sourceContact = contactHelpers.buildSourceContact userId, contactSource, contactData

  select =
    userId: userId
    sources:
      $in: sourceContact.sources

  switch contactSource
    when constants.contactSource.GOOGLE
      select.googleContactId = sourceContact.googleContactId
    when constants.contactSource.FACEBOOK
      select.fbUserId = sourceContact.fbUserId
    when constants.contactSource.LINKED_IN
      select.liUserId = sourceContact.liUserId
    when constants.contactSource.SENT_MAIL_TOUCH
      select.primaryEmail = sourceContact.primaryEmail

  update =
    $set: sourceContact

  options =
    upsert: true

  winston.doInfo 'addSourceContact',
    select: select
    update: update

  SourceContactModel.findOneAndUpdate select, update, options, (mongoError) ->
    if mongoError

      #TEMP
      winston.doInfo 'addSourceContact mongoError',
        select: select
        update: update
        options: options
        mongoError: mongoError

      console.log 'mongoError: ', mongoError

      winston.doMongoError mongoError

      callback winston.makeMongoError mongoError
      return
    callback()


exports.mergeContactsFromSourceContact = (userId, sourceContact, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless sourceContact then callback winston.makeMissingParamError 'sourceContact'; return

  contactHelpers.matchExistingContacts userId, sourceContact, (error, existingContacts) ->
    if error then callback error; return

    contactsToDeleteOnMerge = []
    contactToSave = new ContactModel sourceContact
    if existingContacts and existingContacts.length
      contactToSave = existingContacts[0]

      #check for multi-merge (and delete) situation
      if existingContacts.length > 1
        for i in [1...existingContacts.length]
          existingContact = existingContacts[i]
          contactHelpers.mergeContacts contactToSave, existingContact
          contactsToDeleteOnMerge.push existingContact

      contactHelpers.mergeContacts contactToSave, contact

    contactHelpers.saveContact contactToSave, (error) ->
      if error then callback error; return

      contactHelpers.deleteContactsWithReplacement userId, contactsToDeleteOnMerge, contactToSave, (error) ->
        if error then callback error; return
        callback null, contactToSave


exports.saveContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return

  contactHelpers.setLowerCaseFields contact
  contact = contactHelpers.cleanDummyFields contact

  contact.save (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    callback()


exports.cleanDummyFields = (contact) ->
  unless contact then winston.doMissingParamError 'contact'; return

  contact.numTouches = undefined
  contact.imageURLs = undefined
  contact


exports.deleteContactsWithReplacement = (userId, contactsToDelete, replacementContact, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return

  contactsToDelete ||= []
  async.each contactsToDelete, (contactToDelete, eachCallback) ->

    unless replacementContact
      contactHelpers.deleteContact contactToDelete, eachCallback
      return

    select =
      userId: userId
      contactId: contactToDelete._id

    update =
      $set:
        contactId: replacementContact._id

    options =
      multi: true

    TouchModel.update select, update, options, (mongoError) ->
      if mongoError then eachCallback winston.makeMongoError mongoError; return
      contactHelpers.deleteContact contactToDelete, eachCallback
    
  , callback


exports.deleteContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return

  # Delete images from s3
  contact.imageS3Filenames ||= []
  async.each contact.imageS3Filenames, (imageS3Filename, eachCallback) ->
    imageUtils.deleteContactImage imageS3Filename, (error) ->
      if error
        eachCallback winston.makeError 'deleteContactImage failed',
          contactId: contact._id
          imageS3Filename: imageS3Filename
          deleteError: error
      else
        eachCallback()
  , (error) ->
    if error
      winston.handleError error

    contact.remove (error) ->
      if error then callback winston.makeMongoError error; return
      callback()


# NOTE: contact can be either a sourceContact or a normal contact
exports.matchExistingContacts = (userId, contact, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless contact then callback winston.makeMissingParamError 'contact'; return

  unless ( contact.emails and contact.emails.length ) or contact.lastNameLower
    winston.doWarn 'contactHelpers.matchExistingContacts: no emails or lastNameLower to match on',
      contact: contact
    callback()
    return

  select =
    userId: userId
    '$or': []
    _id:
      '$ne': contact._id

  if contact.emails and contact.emails.length
    select['$or'].push
      emails:
        '$in': contact.emails

  if contact.lastNameLower
    selectNameMatch =
      lastNameLower: contact.lastNameLower

    if contact.firstNameLower
      selectNameMatch.firstNameLower = contact.firstNameLower

    select['$or'].push selectNameMatch

  ContactModel.find select, (mongoError, dbMatchedContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless dbMatchedContacts and dbMatchedContacts.length
      callback()
      return

    foundEmailMatch = false
    matchedContacts = []
    for dbMatchedContact in dbMatchedContacts
      unless contact.emails and contact.emails.length and dbMatchedContact.emails and dbMatchedContact.emails.length
        continue

      for contactEmail in contact.emails
        contactEmailIndex = dbMatchedContact.emails.indexOf contactEmail
        if contactEmailIndex isnt -1
          foundEmailMatch = true
          matchedContacts.push dbMatchedContact
          break

    #Email is a strong match, so if we found any of those, return them all
    # (they will all be merged together)
    if foundEmailMatch
      callback null, matchedContacts
      return

    if dbMatchedContacts.length > 1
      #Multiple matches, without a 'strong' match (e.g. email).
      # Not enough confidence to pick one, so don't do a match.
      winston.doWarn 'multiple matching contacts!',
        numMatches: dbMatchedContacts.length
        contact: contact
        dbMatchedContacts: dbMatchedContacts
      callback()
      return

    #There's only one, so that's our match
    matchedContacts.push dbMatchedContacts[0]
    callback null, matchedContacts


exports.buildSourceContact = (userId, contactSource, sourceContactData) ->

  contactData =
    userId: userId
    imageSourceURLs: []
    sources: [contactSource]

  if contactSource is constants.contactSource.GOOGLE
    contactData.googleContactId = sourceContactData._id
    contactData.googleUserId = sourceContactData.googleUserId
    contactData.primaryEmail = emailUtils.normalizeEmailAddress sourceContactData.primaryEmail
    contactData.emails = emailUtils.normalizeEmailAddressArray sourceContactData.emails
    contactData.firstName = sourceContactData.firstName
    contactData.middleName = sourceContactData.middleName
    contactData.lastName = sourceContactData.lastName

  else if contactSource is constants.contactSource.FACEBOOK
    contactData.fbUserId = sourceContactData._id
    if sourceContactData.email
      contactData.primaryEmail = emailUtils.normalizeEmailAddress sourceContactData.email
      contactData.emails = emailUtils.normalizeEmailAddressArray [sourceContactData.email]
    contactData.firstName = sourceContactData.first_name
    contactData.middleName = sourceContactData.middle_name
    contactData.lastName = sourceContactData.last_name
    fbImageURL = fbHelpers.getImageURL sourceContactData._id
    if fbImageURL
      contactData.imageSourceURLs.push fbImageURL

  else if contactSource is constants.contactSource.LINKED_IN
    contactData.liUserId = sourceContactData._id
    if sourceContactData.emailAddress
      contactData.primaryEmail = emailUtils.normalizeEmailAddress sourceContactData.emailAddress
      contactData.emails = emailUtils.normalizeEmailAddressArray [sourceContactData.emailAddress]
    contactData.firstName = sourceContactData.firstName
    contactData.lastName = sourceContactData.lastName
    if sourceContactData.pictureUrl
      contactData.imageSourceURLs.push sourceContactData.pictureUrl

  else if contactSource is constants.contactSource.SENT_MAIL_TOUCH
    if sourceContactData.email
      contactData.primaryEmail = emailUtils.normalizeEmailAddress sourceContactData.email
      contactData.emails = emailUtils.normalizeEmailAddressArray [sourceContactData.email]
    contactData.googleUserId = sourceContactData.googleUserId
    contactData.firstName = sourceContactData.firstName
    contactData.middleName = sourceContactData.middleName
    contactData.lastName = sourceContactData.lastName

  utils.removeNullFields contactData, true, true
  contact = new ContactModel contactData
  contactHelpers.setLowerCaseFields contact
  contact


exports.setLowerCaseFields = (contact) ->
  unless contact then return

  fieldNames = [
    'firstName'
    'middleName'
    'lastName'
  ]

  for fieldName in fieldNames
    fieldNameLower = fieldName + 'Lower'
    if contact[fieldName]
      contact[fieldNameLower] = contact[fieldName].toLowerCase()
    else
      contact[fieldNameLower] = undefined


exports.mergeContacts = (existingContact, newContact) ->
  unless newContact then return existingContact

  mergeFields = [
    'googleContactId'
    'fbUserId'
    'liUserId'
    'primaryEmail'
    'firstName'
    'middleName'
    'lastName'
  ]

  for mergeField in mergeFields
    if newContact[mergeField]
      existingContact[mergeField] = newContact[mergeField]

  arrayMergeFields = [
    'emails'
    'imageS3Filenames'
    'imageSourceURLs'
    'sources'
  ]

  for arrayMergeField in arrayMergeFields

    existingContact[arrayMergeField] ||= []

    unless newContact[arrayMergeField] and newContact[arrayMergeField].length
      continue

    for value in newContact[arrayMergeField]
      existingContactArrayMergeFieldIndex = existingContact[arrayMergeField].indexOf value
      if existingContactArrayMergeFieldIndex is -1
        existingContact[arrayMergeField].push value

  contactHelpers.setLowerCaseFields existingContact
  existingContact


exports.parseFullName = (fullName) ->
  result =
    firstName: null
    middleName: null
    lastName: null

  fullName = contactHelpers.cleanFullName fullName
  unless fullName then return result

  #ordering matters here
  clearNamePrefixResult = contactHelpers.clearNamePrefix fullName
  fullName = clearNamePrefixResult.fullName
  foundPrefix = clearNamePrefixResult.foundPrefix
  fullName = contactHelpers.clearNameSuffixes fullName
  fullName = contactHelpers.flipAroundComma fullName
  fullNameSplit = contactHelpers.fixLastNamePrefix fullName

  if fullNameSplit.length is 0
    return result

  if fullNameSplit.length is 1
    if foundPrefix
      result.lastName = fullNameSplit[0]
    else
      result.firstName = fullNameSplit[0]
    return result

  if fullNameSplit.length is 2
    result.firstName = fullNameSplit[0]
    result.lastName = fullNameSplit[1]
    return result

  result.firstName = fullNameSplit[0]
  middleNameSplit = fullNameSplit.slice 1, ( fullNameSplit.length - 1 )
  result.middleName = middleNameSplit.join ' '
  result.lastName = fullNameSplit[ fullNameSplit.length - 1 ]
  return result


exports.clearNamePrefix = (fullName) ->
  fullName = contactHelpers.cleanFullName fullName
  result =
    fullName: fullName
    foundPrefix: false
  unless fullName then return result

  prefixes = constants.NAME_PREFIXES
  fullNameSplit = fullName.split ' '

  unless fullNameSplit.length > 0
    return result

  firstLowerCase = fullNameSplit[0].toLowerCase()
  firstLowerCase = firstLowerCase.replace /\./g, ''

  if prefixes.indexOf( firstLowerCase ) isnt -1
    fullNameSplit.splice 0, 1
    result.foundPrefix = true

  fullName = fullNameSplit.join ' '
  result.fullName = fullName
  result


exports.clearNameSuffixes = (fullName) ->
  fullName = contactHelpers.cleanFullName fullName
  unless fullName then return fullName

  suffixes = constants.NAME_SUFFIXES

  fullNameNoCommas = fullName.replace /,/g, ' '
  fullNameNoCommas = contactHelpers.cleanFullName fullNameNoCommas
  fullNameSplit = fullNameNoCommas.split ' '

  while true
    unless fullNameSplit.length > 0
      break
    lastLowerCase = fullNameSplit[ fullNameSplit.length - 1 ].toLowerCase()
    lastLowerCase = lastLowerCase.replace /\./g, ''
    if suffixes.indexOf( lastLowerCase ) isnt -1
      fullNameSplit.splice ( fullNameSplit.length - 1 ), 1
    else
      break

  #Now put everything back in place up to the new last piece
  #  (replaces any existing, meaningful commas)
  newLast = fullNameSplit[ fullNameSplit.length - 1 ]
  newLastIndex = fullName.indexOf newLast
  if newLastIndex is -1
    winston.doError 'cleraNameSuffixes: lost the last piece, somehow'
    return fullName
  fullName = fullName.substring 0, newLastIndex + newLast.length
  fullName


exports.flipAroundComma = (fullName) ->
  fullName = contactHelpers.cleanFullName fullName
  unless fullName then return fullName

  commaIndex = fullName.indexOf ','
  if commaIndex is '-1' then return fullName

  newFirstPart = fullName.substring( commaIndex + 1 )
  newLastPart = fullName.substring( 0, commaIndex )

  fullName = newFirstPart + ' ' + newLastPart
  fullName = fullName.trim()
  fullName


exports.fixLastNamePrefix = (fullName) ->
  fullName = contactHelpers.cleanFullName fullName
  fullNameSplit = fullName.split ' '

  unless fullNameSplit.length > 2
    return fullNameSplit

  lastNamePrefixes = constants.LAST_NAME_PREFIXES

  secondToLast = fullNameSplit[ fullNameSplit.length - 2 ]
  secondToLastLowerCase = secondToLast.toLowerCase()

  if constants.LAST_NAME_PREFIXES.indexOf( secondToLastLowerCase ) isnt -1
    fullNameSplit.splice ( fullNameSplit.length - 2 ), 1
    fullNameSplit[ fullNameSplit.length - 1 ] = secondToLast + ' ' + fullNameSplit[ fullNameSplit.length - 1 ]

  fullNameSplit


exports.cleanFullName = (fullName) ->
  unless fullName then return ''
  unless utils.isString fullName then return ''

  fullName = fullName.trim()
  unless fullName then return fullName

  fullNameSplit = fullName.split ' '

  for value, index in fullNameSplit
    value = value.trim()
    fullNameSplit[index] = value

  fullNameSplitNoEmpties = []
  for value, index in fullNameSplit
    if value isnt ''
      fullNameSplitNoEmpties.push value
  fullNameSplit = fullNameSplitNoEmpties

  fullName = fullNameSplit.join ' '
  fullName


#Drop any fields we don't want to send to the client
exports.sanitizeContact = (contact) ->
  unless contact then return {}

  fieldsToRemove = [
    '__v'
    'timestamp'
    'firstNameLower'
    'middleNameLower'
    'lastNameLower'
    'imageS3Filenames'
  ]

  for field in fieldsToRemove
    contact[field] = undefined

  contact


exports.getAllContactsWithTouchCounts = (userId, callback) ->
  unless userId then callback winston.makeMissingParamError userId; return

  select =
    userId: userId

  ContactModel.find select, (mongoError, contacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    contacts ||= []
    for contact, index of contacts
      contacts[index] = contactHelpers.sanitizeContact contact

    mapReduce =
      query:
        userId: userId
      map: () ->
        emit this.contactId, 1
      reduce: (key, values) ->
        Array.sum values

    TouchModel.mapReduce mapReduce, (mongoError, mrResults) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      mrResults ||= []
      firstResult = null
      if mrResults and mrResults.length
        firstResult = mrResults[0]

      for contact, index in contacts
        contact.numTouches = 0
        for mrResult in mrResults
          mrResultContactId = mrResult._id

          if mrResult._id.toString() is contact._id.toString()
            contact.numTouches = mrResult.value
            break

      callback null, contacts


exports.signImageURLs = (contact) ->
  unless contact then wiston.doMissingParamError 'contact'; return

  contact.imageS3Filenames ||= []
  contact.imageURLs ||= []
  for imageS3Filename in contact.imageS3Filenames
    s3Path = imageUtils.getContactImageS3Path imageS3Filename
    imageURL = s3Utils.signedURL s3Path
    contact.imageURLs.push imageURL


exports.mergeContacts = (userId, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return

  # Same lock for mergeContacts and importContactImages
  lockKeyPrefix = constants.lock.keyPrefix.cleanupContacts
  lockKey = lockKeyPrefix + userId

  lockUtils.acquireLock lockKey, (error, success) ->
    if error then callback error; return
    unless success then callback winston.makeError 'failed to get cleanupContacts lock'; return
  
    select =
      userId: userId

    SourceContactModel.find select, (mongoError, sourceContacts) ->
      if mongoError
        lockUtils.releaseLock lockKey, (error) ->
          if error then winston.handleError error
        callback winston.makeMongoError mongoError
        return

      sourceContacts ||= []
      async.eachSeries sourceContacts, (sourceContact, eachSeriesCallback) ->
        contactHelpers.mergeContactsFromSourceContact userId, sourceContact, eachSeriesCallback

      , (error) ->
        lockUtils.releaseLock lockKey, (error) ->
          if error then winston.handleError error

        if error then callback error; return

        importContactImagesJob =
          userId: userId

        sqsUtils.addJobToQueue conf.queue.importContactImages, importContactImagesJob, callback


exports.importContactImages = (userId, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return

  # Same lock for mergeContacts and importContactImages
  lockKeyPrefix = constants.lock.keyPrefix.cleanupContacts
  lockKey = lockKeyPrefix + userId

  lockUtils.acquireLock lockKey, (error, success) ->
    if error then callback error; return
    unless success then callback winston.makeError 'failed to get cleanupContacts lock'; return

    select =
      userId: userId

    ContactModel.find select, (mongoError, contacts) ->
      if mongoError
        lockUtils.releaseLock lockKey, (error) ->
          if error then winston.handleError error
        callback winston.makeMongoError mongoError
        return

      contacts ||= []
      async.each contacts, (contact, eachCallback1) ->
        
        contact.imageSourceURLs ||= []
        async.each contact.imageSourceURLs, (imageSourceURL, eachCallback2) ->

          imageUtils.importContactImage imageSourceURL, contact, (error) ->
            if error
              eachCallback2 winston.makeError 'importContactImage failed',
                contactId: contact._id
                imageSourceURL: imageSourceURL
                importError: error
                contactImageURLs: contact.sourceImageURLs
            else
              eachCallback2()

        , eachCallback1

      , (error) ->
        lockUtils.releaseLock lockKey, (error) ->
          if error then winston.handleError error

        callback error