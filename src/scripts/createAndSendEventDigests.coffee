#!/usr/local/bin/node

async = require 'async'

utils = require '../lib/utils'
winston = require('../lib/winstonWrapper').winston
mongooseConnect = require('../lib/mongooseConnect')
appInitUtils = require '../lib/appInitUtils'
emailUtils = require '../lib/emailUtils'

UserModel = require('../schema/user').UserModel
EventDigestModel = require('../schema/eventDigest').EventDigestModel
eventDigestHelpers = require '../lib/eventDigestHelpers'

initActions = [
  appInitUtils.CONNECT_MONGO
]


postInit = () ->
  run (error) ->
    if error
      winston.handleError error
    mongooseConnect.disconnect()
    winston.doInfo 'Done.'


run = (callback) ->
  select = {}

  UserModel.find select, (mongoError, users) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    winston.doInfo 'got users: ',
      users: users

    async.each users, createAndSendEventDigest, (error) ->
      callback error


createAndSendEventDigest = (user, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return

  winston.doInfo 'createAndSendEventDigest'

  winston.doInfo 'user: ',
    user: user

  select =
    userId: user._id
    digestDate: utils.getDateString()

  winston.doInfo 'select',
    select: select

  EventDigestModel.find select, (mongoError, eventDigest) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if eventDigest
      if eventDigest.hasBeenEmailed
        callback()
      else
        eventDigestHelpers.populateEvents eventDigest, (error) ->
          if error then callback error; return

          sendEventDigestEmail eventDigest, user, callback
    else
      eventDigestHelpers.buildAndSaveEventDigest user, (error, eventDigest) ->
        if error then callback error; return

        sendEventDigestEmail eventDigest, user, callback


sendEventDigestEmail = (eventDigest, user, callback) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return

  winston.doInfo 'sendEventDigestEmail'

  emailUtils.sendEventDigestEmail eventDigest, user, (error) ->
    if error then callback error; return
    
    eventDigest.hasBeenEmailed = true
    eventDigest.save (mongoError) ->
      if mongoError
        callback winston.makeMongoError mongoError
      else
        callback()


#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'CreateAndSendEventDigests', initActions, postInit