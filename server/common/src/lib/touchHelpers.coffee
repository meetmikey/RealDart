async = require 'async'

winston = require('./winstonWrapper').winston
ContactModel = require('../schema/contact').ContactModel
TouchModel = require('../schema/touch').TouchModel
mailUtils = require './mailUtils'

touchHelpers = this


exports.addTouchesFromEmail = (userId, emailJSON, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless emailJSON then callback winston.makeMissingParamError 'emailJSON'; return

  recipientEmails = emailJSON.recipientEmails
  unless recipientEmails and recipientEmails.length
    winston.doWarn 'no recipientEmails in emailJSON',
      emailJSON: emailJSON
    callback()
    return

  #For efficiency, select all the contacts at once then match them up
  select =
    userId: emailJSON.userId
    emails:
      '$in': recipientEmails

  ContactModel.find select, (mongoError, foundContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    contactIds = touchHelpers.matchContactsToEmails foundContacts, recipientEmails
    async.each contactIds, (contactId, eachCallback) ->
      touch = new TouchModel
        userId: userId
        contactId: contactId
        type: 'email'
        emailSubject = mailUtils.getCleanSubject emailJSON.subject
        date: emailJSON.date

      touch.save (mongoError) ->
        if mongoError then eachCallback winston.makeMongoError mongoError; return
        eachCallback()

    , callback


exports.matchContactsToEmails = (contacts, emails) ->
  unless emails and emails.length then return []

  contactIds = []
  for email in emails
    contactId = null
    for contact in contacts
      if contact.emails.indexOf( email ) isnt -1
        if contactId
          winston.doError 'More than one matching contact for email',
            email: email
        contactId = contact._id

    if contactId
      contactIds.push contactId
    else
      winston.doError 'no matching contact for email',
        email: email

  contactIds