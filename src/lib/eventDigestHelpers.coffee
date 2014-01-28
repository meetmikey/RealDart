constants = require '../constants'
utils = require('./utils')
winston = require('./winstonWrapper').winston
EventDigestModel = require('../schema/eventDigest').EventDigestModel
EventModel = require('../schema/event').EventModel
FBUserModel = require('../schema/fbUser').FBUserModel

eventDigestHelpers = this


exports.buildAndSaveEventDigest = (user, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return

  eventDigest = new EventDigestModel
    userId: user._id
    eventIds: []
    digestDate: utils.getDateString()
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

  emailText = 'Your RealDart events for ' + eventDigest.digestDate + "...\n\n\n"
  for event of eventDigest.events
    switch event.type

      when constants.EVENT_TYPE.BIRTHDAY
        emailText += "It's " + event.fbUser.name + "'s birthday!\n"
        break
    
  callback null, emailText


exports.populateEvents = (eventDigest, callback) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return

  if not utils.isArray eventDigest
    #if they're already present, just callback...
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

  fbHelpers.getFacebookFriends user, (error, facebookFriends) ->
    if error then callback error; return

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