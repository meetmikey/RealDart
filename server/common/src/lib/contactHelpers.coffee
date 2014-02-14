fbHelpers = require './fbHelpers'
ContactModel = require( '../schema/contact').ContactModel
winston = require('./winstonWrapper').winston
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

    contactToSave.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      callback()


exports.matchExistingContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return

  unless contact.email or contact.lastName
    winston.doWarn 'contactHelpers.matchExistingContact: no email or lastName to match on',
      contact: contact
    callback()
    return

  select =
    '$or': []

  if contact.email
    select['$or'].push
      email: contact.email

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
      if contact.email and ( matchedContact.email is contact.email )
        numEmailMatches++
        emailMatch = matchedContact

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

  if service is constants.service.FACEBOOK
    contactData.fbUserId = contactServiceUser._id
    contactData.email = contactServiceUser.email
    contactData.firstName = contactServiceUser.first_name
    contactData.lastName = contactServiceUser.last_name
    contactData.picURL = fbHelpers.getPicURL contactServiceUser._id

  else if service is constants.service.LINKED_IN
    contactData.liUserId = contactServiceUser._id
    contactData.email = contactServiceUser.emailAddress
    contactData.firstName = contactServiceUser.firstName
    contactData.lastName = contactServiceUser.lastName
    contactData.picURL = contactServiceUser.pictureUrl

  contact = new ContactModel contactData
  contact

exports.mergeContacts = (existingContact, newContact) ->
  unless newContact then return existingContact

  mergeFields = [
    'fbUserId'
    'liUserId'
    'email'
    'firstName'
    'lastName'
    'picURL'
  ]

  for mergeField in mergeFields
    if newContact[mergeField]
      existingContact[mergeField] = newContact[mergeField]

  existingContact