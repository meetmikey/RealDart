async = require 'async'
_ = require 'underscore'

winston = require('./winstonWrapper').winston
ContactModel = require('../schema/contact').ContactModel
TouchModel = require('../schema/touch').TouchModel
emailUtils = require './emailUtils'
contactHelpers = require './contactHelpers'

constants = require '../constants'

touchHelpers = this


exports.addTouchesFromEmail = (userId, emailJSON, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless emailJSON then callback winston.makeMissingParamError 'emailJSON'; return

  recipients = emailJSON.recipients
  unless recipients and recipients.length
    winston.doWarn 'no recipients in emailJSON',
      emailJSON: emailJSON
    callback()
    return

  #For efficiency, select all the contacts at once then match them up
  recipientEmails = _.pluck recipients, 'email'
  select =
    userId: emailJSON.userId
    emails:
      '$in': recipientEmails

  ContactModel.find select, (mongoError, foundContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    async.each recipients, (recipient, eachCallback) ->
      touchHelpers.addTouchForEmailRecipient userId, emailJSON, recipient, foundContacts, eachCallback
    , callback


exports.addTouchForEmailRecipient = (userId, emailJSON, recipient, foundContacts, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless emailJSON then callback winston.makeMissingParamError 'emailJSON'; return
  unless recipient then callback winston.makeMissingParamError 'recipient'; return

  googleUserId = emailJSON.googleUserId
  recipientName = recipient.name
  recipientEmail = recipient.email

  unless recipientEmail and emailUtils.isValidEmail recipientEmail
    winston.doWarn 'invalid recipientEmail', {recipientEmail: recipientEmail}
    callback()
    return

  touchHelpers.getContactFromEmail userId, googleUserId, recipientEmail, recipientName, foundContacts, (error, contact) ->
    if error then callback error; return
    unless contact then callback winston.makeError 'no contact', {recipientEmail: recipientEmail}; return

    touch = new TouchModel
      userId: userId
      contactId: contact._id
      type: 'email'
      emailSubject: emailUtils.getCleanSubject emailJSON.subject
      date: emailJSON.date

    touch.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return
      callback()


#As an optimization, a list of probable contact matches is provided.
#If it's in there, we're done.
exports.getContactFromEmail = (userId, googleUserId, email, fullName, contacts, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless email then callback winston.makeMissingParamError 'email'; return

  foundContact = null
  contacts ||= []
  for contact in contacts
    if contact.emails.indexOf( email ) isnt -1
      if foundContact
        winston.doWarn 'More than one matching contact for email',
          email: email
      foundContact = contact

  if foundContact
    callback null, foundContact
    return

  #winston.doInfo 'no matching contact for email, making one...',
  #  email: email

  parsedName = contactHelpers.parseFullName fullName
  userInfo =
    email: email
    firstName: parsedName.firstName
    middleName: parsedName.middleName
    lastName: parsedName.lastName

  #Mark a googleUserId on the contact, so we know which account it came from
  if googleUserId
    userInfo.googleUserId = googleUserId

  contactHelpers.addContact userId, constants.service.SENT_MAIL_TOUCH, userInfo, callback