fbHelpers = require './fbHelpers'
ContactModel = require( '../schema/contact').ContactModel
winston = require('./winstonWrapper').winston
basicUtils = require './basicUtils'
utils = require './utils'

constants = require '../constants'

contactHelpers = this

exports.addContact = (userId, service, contactServiceUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless service then callback winston.makeMissingParamError 'service'; return
  unless contactServiceUser then callback winston.makeMissingParamError 'contactServiceUser'; return

  newContact = contactHelpers.buildContact userId, service, contactServiceUser

  contactHelpers.matchExistingContact newContact, (error, existingContact) ->
    if error then callback error; return

    contactToSave = newContact
    if existingContact
      ###
      winston.doInfo 'found match',
        existingContact: existingContact
        newContact: newContact
      ###

      contactHelpers.mergeContacts existingContact, newContact
      contactToSave = existingContact

    utils.removeNullFields contactToSave, true, true

    contactToSave.save (mongoError) ->
      #if mongoError then callback winston.makeMongoError mongoError; return
      if mongoError
        callback winston.makeMongoError mongoError,
          contactToSave: contactToSave
          contactToSaveEmails: contactToSave?.emails
        return

      callback()


exports.matchExistingContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return

  unless ( contact.emails and contact.emails.length ) or contact.lastName
    winston.doWarn 'contactHelpers.matchExistingContact: no emails or lastName to match on',
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

  ContactModel.find select, (mongoError, matchedContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless matchedContacts and matchedContacts.length
      callback()
      return

    numEmailMatches = 0
    emailMatch = null
    for matchedContact in matchedContacts
      unless contact.emails and contact.emails.length and matchedContact.emails and matchedContact.emails.length
        continue

      for contactEmail in contact.emails
        contactEmailIndex = matchedContact.emails.indexOf contactEmail
        if contactEmailIndex isnt -1
          numEmailMatches++
          emailMatch = matchedContact
          break

    #Email is a strong match, so if there's only one email match, use it.
    # (even if there are other non-email matches)
    if numEmailMatches is 1
      callback null, emailMatch
      return

    if matchedContacts.length > 1
      #Multiple matches, without a 'strong' match (e.g. email).
      # Not enough confidence to pick one, so don't do a match.
      winston.doWarn 'multiple matching contacts!',
        numMatches: matchedContacts.length
        contact: contact
        matchedContacts: matchedContacts
      callback()
      return

    #There's only one, so that's our match
    matchedContact = matchedContacts[0]
    callback null, matchedContact


exports.buildContact = (userId, service, contactServiceUser) ->

  contactData =
    userId: userId

  if service is constants.service.GOOGLE
    contactData.googleContactId = contactServiceUser._id
    contactData.googleUserId = contactServiceUser.googleUserId
    contactData.primaryEmail = contactServiceUser.primaryEmail
    contactData.emails = contactServiceUser.emails
    contactData.firstName = contactServiceUser.firstName
    contactData.lastName = contactServiceUser.lastName

  else if service is constants.service.FACEBOOK
    contactData.fbUserId = contactServiceUser._id
    if contactServiceUser.email
      contactData.primaryEmail = contactServiceUser.email
      contactData.emails = [contactServiceUser.email]
    contactData.firstName = contactServiceUser.first_name
    contactData.middleName = contactServiceUser.middle_name
    contactData.lastName = contactServiceUser.last_name
    contactData.picURL = fbHelpers.getPicURL contactServiceUser._id

  else if service is constants.service.LINKED_IN
    contactData.liUserId = contactServiceUser._id
    if contactServiceUser.emailAddress
      contactData.primaryEmail = contactServiceUser.emailAddress
      contactData.emails = [contactServiceUser.emailAddress]
    contactData.firstName = contactServiceUser.firstName
    contactData.lastName = contactServiceUser.lastName
    contactData.picURL = contactServiceUser.pictureUrl

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
