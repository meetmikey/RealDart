async = require 'async'

fbHelpers = require './fbHelpers'
ContactModel = require( '../schema/contact').ContactModel
TouchModel = require( '../schema/touch').TouchModel
winston = require('./winstonWrapper').winston
basicUtils = require './basicUtils'
mailUtils = require './mailUtils'
utils = require './utils'

constants = require '../constants'

contactHelpers = this

exports.addContact = (userId, service, contactServiceUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless service then callback winston.makeMissingParamError 'service'; return
  unless contactServiceUser then callback winston.makeMissingParamError 'contactServiceUser'; return

  newContact = contactHelpers.buildContact userId, service, contactServiceUser

  contactHelpers.matchExistingContacts newContact, (error, existingContacts) ->
    if error then callback error; return

    contactsToDelete = []
    contactToSave = newContact
    if existingContacts and existingContacts.length
      contactToSave = existingContacts[0]

      #check for multi-merge (and delete) situation
      if existingContacts.length > 1
        for i in [1...existingContacts.length]
          existingContact = existingContacts[i]
          contactHelpers.mergeContacts contactToSave, existingContact
          contactsToDelete.push existingContact

      contactHelpers.mergeContacts contactToSave, newContact

    utils.removeNullFields contactToSave, true, true
    contactToSave.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      contactHelpers.deleteContactsWithReplacement contactsToDelete, contactToSave, (error) ->
        if error then callback error; return
        callback null, contactToSave


exports.deleteContactsWithReplacement = (contactsToDelete, replacementContact, callback) ->
  contactsToDelete = contactsToDelete || []
  async.each contactsToDelete, (contactToDelete, eachCallback) ->

    unless replacementContact
      contactHelpers.deleteContact contactToDelete, eachCallback
      return

    select =
      contactId: contactToDelete._id

    update =
      $set:
        contactId: replacementContact._id

    options:
      multi: true

    TouchModel.update select, update, options, (mongoError) ->
      if mongoError then eachCallback winston.makeMongoError mongoError; return
      contactHelpers.deleteContact contactToDelete, eachCallback
    
  , callback


exports.deleteContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return
  contact.remove (error) ->
    if error then callback winston.makeMongoError error; return
    callback()


exports.matchExistingContacts = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return

  unless ( contact.emails and contact.emails.length ) or contact.lastName
    winston.doWarn 'contactHelpers.matchExistingContacts: no emails or lastName to match on',
      contact: contact
    callback()
    return

  select =
    '$or': []

  if contact.emails and contact.emails.length
    select['$or'].push
      emails:
        '$in': contact.emails

  if contact.lastName
    selectNameMatch =
      lastName: contact.lastName

    if contact.firstName
      selectNameMatch.firstName = contact.firstName

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


exports.buildContact = (userId, service, contactServiceUser) ->

  contactData =
    userId: userId

  if service is constants.service.GOOGLE
    contactData.googleContactId = contactServiceUser._id
    contactData.googleUserId = contactServiceUser.googleUserId
    contactData.primaryEmail = mailUtils.normalizeEmailAddress contactServiceUser.primaryEmail
    contactData.emails = mailUtils.normalizeEmailAddressArray contactServiceUser.emails
    contactData.firstName = contactServiceUser.firstName
    contactData.middleName = contactServiceUser.middleName
    contactData.lastName = contactServiceUser.lastName

  else if service is constants.service.FACEBOOK
    contactData.fbUserId = contactServiceUser._id
    if contactServiceUser.email
      contactData.primaryEmail = mailUtils.normalizeEmailAddress contactServiceUser.email
      contactData.emails = mailUtils.normalizeEmailAddressArray [contactServiceUser.email]
    contactData.firstName = contactServiceUser.first_name
    contactData.middleName = contactServiceUser.middle_name
    contactData.lastName = contactServiceUser.last_name
    contactData.picURL = fbHelpers.getPicURL contactServiceUser._id

  else if service is constants.service.LINKED_IN
    contactData.liUserId = contactServiceUser._id
    if contactServiceUser.emailAddress
      contactData.primaryEmail = mailUtils.normalizeEmailAddress contactServiceUser.emailAddress
      contactData.emails = mailUtils.normalizeEmailAddressArray [contactServiceUser.emailAddress]
    contactData.firstName = contactServiceUser.firstName
    contactData.lastName = contactServiceUser.lastName
    contactData.picURL = contactServiceUser.pictureUrl

  else if service is constants.service.SENT_MAIL_TOUCH
    if contactServiceUser.email
      contactData.primaryEmail = mailUtils.normalizeEmailAddress contactServiceUser.email
      contactData.emails = mailUtils.normalizeEmailAddressArray [contactServiceUser.email]
    contactData.firstName = contactServiceUser.firstName
    contactData.middleName = contactServiceUser.middleName
    contactData.lastName = contactServiceUser.lastName

  contact = new ContactModel contactData
  utils.removeNullFields contact, true, true
  contact

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
    'picURL'
  ]

  for mergeField in mergeFields
    if newContact[mergeField]
      existingContact[mergeField] = newContact[mergeField]

  arrayMergeFields = [
    'emails'
  ]

  for arrayMergeField in arrayMergeFields

    existingContact[arrayMergeField] = existingContact[arrayMergeField] || []

    unless newContact[arrayMergeField] and newContact[arrayMergeField].length
      continue

    for value in newContact[arrayMergeField]
      existingContactArrayMergeFieldIndex = existingContact[arrayMergeField].indexOf value
      if existingContactArrayMergeFieldIndex is -1
        existingContact[arrayMergeField].push value

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
