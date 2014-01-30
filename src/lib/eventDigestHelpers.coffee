async = require 'async'

constants = require '../constants'
utils = require('./utils')
winston = require('./winstonWrapper').winston
fbHelpers = require('./fbHelpers')
emailUtils = require './emailUtils'

EventDigestModel = require('../schema/eventDigest').EventDigestModel
EventModel = require('../schema/event').EventModel
FBUserModel = require('../schema/fbUser').FBUserModel

eventDigestHelpers = this

exports.buildAndSaveEventDigest = (user, digestDate, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return

  winston.doInfo 'buildAndSaveEventDigest'

  eventDigest = new EventDigestModel
    userId: user._id
    eventIds: []
    digestDate: digestDate
    hasBeenEmailed: false
    events: []

  eventDigestHelpers.addFacebookBirthdayEvents eventDigest, user, (error) ->
    if error then callback error; return

    eventCache = eventDigest.events
    eventDigest.events = null
    eventDigest.save (mongoError) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      eventDigest.events = eventCache
      callback null, eventDigest


exports.getEventDigestEmailText = (eventDigest, user, callback) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return
  unless user then callback winston.makeMissingParamError 'user'; return

  emailTemplateData = eventDigestHelpers.getEmailTemplateData eventDigest, user
  emailHTML = emailUtils.getEmailTemplateHTML 'eventDigestEmail', emailTemplateData
    
  callback null, emailHTML


exports.getEmailTemplateData = (eventDigest, user) ->
  templateData =
    digestDate: eventDigest.digestDate
    events: []

  for event in eventDigest.events
    templateDataEvent =
      type: event.type

    switch event.type
      when constants.EVENT_TYPE.BIRTHDAY
        templateDataEvent.name = fbHelpers.getPrintableName( event.fbUser )

    templateData.events.push templateDataEvent

  templateData

exports.populateEvents = (eventDigest, callback) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return

  winston.doInfo 'populateEvents'

  if utils.isArray eventDigest.events
    #if they're already present, just callback...
    callback()
  else if ( not utils.isArray eventDigest.eventIds ) or ( eventDigest.eventIds.length is 0 )
    callback()
  else
    select =
      _id:
        $in: eventDigest.eventIds

    EventModel.find select, (mongoError, events) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      #TODO: batch this into one mongo query, then assign the fbUser results to the events
      async.each events, (event, eachCallback) ->
        
        select:
          _id: event.fbUserId

        FBUserModel.find select, (mongoError, fbUser) ->
          if mongoError then eachCallback winston.makeMongoError mongoError; return

          event.fbUser = fbUser
          eachCallback()

      , (error) ->
        if error then callback error; return

        eventDigest.events = events
        callback()


exports.addFacebookBirthdayEvents = (eventDigest, user, callback) ->
  unless eventDigestHelpers then callback winston.makeMissingParamError 'eventDigest'; return
  unless user then callback winston.makeMissingParamError 'user'; return

  winston.doInfo 'addFacebookBirthdayEvents'

  fbHelpers.getFacebookFriends user, (error, facebookFriends) ->
    if error then callback error; return

    async.each facebookFriends, (facebookFriend, eachCallback) ->
      
      if eventDigestHelpers.isBirthday( facebookFriend.birthday_date, eventDigest.digestDate )
        event = new EventModel
          userId: user._id
          fbUserId: facebookFriend._id
          type: constants.EVENT_TYPE.BIRTHDAY

        event.save (mongoError) ->
          if mongoError then eachCallback winston.makeMongoError mongoError; return

          event.fbUser = facebookFriend
          eventDigest.eventIds.push event._id
          eventDigest.events.push event
          eachCallback()
      else
        eachCallback()

    , callback

exports.isBirthday = (fbBirthdayDate, compareDate) ->
  #fbBirthdayDate: "11/05" or "06/24/1985" or undefined
  #compareDate: "2014-01-28"
  if not fbBirthdayDate or not compareDate
    return false

  fbBirthdayMonth = fbBirthdayDate.substring 0, 2
  fbBirthdayDay = fbBirthdayDate.substring 3, 5

  compareDateMonth = compareDate.substring 5, 7
  compareDateDay = compareDate.substring 8, 10

  if ( fbBirthdayMonth is compareDateMonth ) and ( fbBirthdayDay is compareDateDay )
    return true
  return false