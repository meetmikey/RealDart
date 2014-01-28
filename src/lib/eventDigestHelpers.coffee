async = require 'async'

constants = require '../constants'
utils = require('./utils')
winston = require('./winstonWrapper').winston
fbHelpers = require('./fbHelpers')

EventDigestModel = require('../schema/eventDigest').EventDigestModel
EventModel = require('../schema/event').EventModel
FBUserModel = require('../schema/fbUser').FBUserModel

eventDigestHelpers = this

exports.buildAndSaveEventDigest = (user, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return

  winston.doInfo 'buildAndSaveEventDigest'

  eventDigest = new EventDigestModel
    userId: user._id
    eventIds: []
    digestDate: utils.getDateString()
    hasBeenEmailed: false
    events: []

  winston.doInfo 'new digest',
    eventDigest: eventDigest

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

  winston.doInfo 'getEventDigestEmailText'

  emailText = 'Your RealDart events for ' + eventDigest.digestDate + "...\n\n\n"
  for event of eventDigest.events
    switch event.type

      when constants.EVENT_TYPE.BIRTHDAY
        emailText += "It's " + event.fbUser.name + "'s birthday!\n"
        break
    
  callback null, emailText


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

    winston.doInfo 'find1',
      select: select
    EventModel.find select, (mongoError, events) ->
      if mongoError then callback winston.makeMongoError mongoError; return

      #TODO: batch this into one mongo query, then assign the fbUser results to the events
      async.each events, (event, eachCallback) ->
        
        select:
          _id: event.fbUserId

        winston.doInfo 'find2'
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

    winston.doInfo 'facebookFriends',
      facebookFriends: facebookFriends

    async.each facebookFriends, (facebookFriend, eachCallback) ->
      
      winston.doInfo 'checking birthday'
        fbFriendBDay: facebookFriend.birthday
        day: eventDigest.digestDate

      if facebookFriend.birthday is eventDigest.digestDate
        event = new EventModel
          userId: user._id
          fbUserId: facebookFriend._id
          type: constants.EVENT_TYPE.BIRTHDAY

        event.save (mongoError) ->
          if mongoError then eachCallback winston.makeMongoError mongoError; return

          event.fbUser = facebookFriend
          eventDigest.eventIds.push event._id
          eachCallback()

    , callback