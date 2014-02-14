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
      #winston.doInfo 'found match',
      #  existingContact: existingContact
      #  newContact: newContact

      contactHelpers.mergeContacts existingContact, newContact
      contactToSave = existingContact

    contactToSave.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      callback()


exports.matchExistingContact = (contact, callback) ->
  unless contact then callback winston.makeMissingParamError 'contact'; return
  unless contact.lastName then callback winston.makeMissingParamError 'contact.lastName'; return

  select =
    lastName: contact.lastName

  if contact.firstName
    select.firstName = contact.firstName

  ContactModel.find select, (mongoError, matchedContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless matchedContacts and matchedContacts.length
      callback()
      return

    if matchedContacts.length > 1
      winston.doWarn 'multiple matching contacts!',
        numMatches: matchedContacts.length
        contact: contact
        matchedContacts: matchedContacts

    matchedContact = matchedContacts[0]
    callback null, matchedContact


exports.buildContact = (userId, service, contactServiceUser) ->

  contactData =
    userId: userId

  if service is constants.service.FACEBOOK
    contactData.fbUserId = contactServiceUser._id
    contactData.firstName = contactServiceUser.first_name
    contactData.lastName = contactServiceUser.last_name
    contactData.picURL = fbHelpers.getPicURL contactServiceUser._id
  else if service is constants.service.LINKED_IN
    contactData.liUserId = contactServiceUser._id
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
    'firstName'
    'lastName'
    'picURL'
  ]

  for mergeField in mergeFields
    if newContact[mergeField]
      existingContact[mergeField] = newContact[mergeField]

  existingContact