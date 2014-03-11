async = require 'async'
_ = require 'underscore'

winston = require('./winstonWrapper').winston
ContactModel = require('../schema/contact').ContactModel
TouchModel = require('../schema/touch').TouchModel
emailUtils = require './emailUtils'
contactHelpers = require './contactHelpers'

constants = require '../constants'

touchHelpers = this


exports.addTouchesForEmail = (userId, email, callback) ->
  unless userId then callback winston.doMissingParamError 'userId'; return
  unless email then callback winston.doMissingParamError 'email'; return

  recipients = email.recipients || []
  unless recipients and recipients.length
    winston.doWarn 'no recipients in email',
      email: email
    callback()
    return

  #For efficiency, select all the contacts at once then match them up
  recipientEmails = _.pluck recipients, 'email'
  select =
    userId: email.userId
    emails:
      '$in': recipientEmails

  ContactModel.find select, (mongoError, foundContacts) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    async.each recipients, (recipient, eachCallback) ->

      recipientEmail = recipient.email
      touchHelpers.getContactByEmailFromArray userId, recipientEmail, foundContacts, (error, contact) ->
        if error then eachCallback error; return

        unless contact
          # I want to see this error, but it's not a reason to fail this job.
          #  At this point, the contact should REALLY be here.  It's already been added as a 
          #  sourceContact and merged into contacts.
          winston.doError 'no contact',
            recipientEmail: recipientEmail
          eachCallback()
          return

        touch = new TouchModel
          userId: userId
          contactId: contact._id
          type: 'email'
          emailId: email._id
          emailSubject: emailUtils.getCleanSubject email.subject
          date: email.date

        touch.save (mongoError) ->
          if mongoError then eachCallback winston.makeMongoError mongoError; return
          eachCallback()

    , callback


exports.getContactByEmailFromArray = (userId, email, contacts, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless email then callback winston.makeMissingParamError 'email'; return

  foundContact = null
  contacts ||= []
  for contact in contacts
    if contact.emails.indexOf( email ) isnt -1
      if foundContact
        winston.doWarn 'getContactByEmailFromArray: More than one matching contact for email',
          email: email
      foundContact = contact

  callback null, foundContact