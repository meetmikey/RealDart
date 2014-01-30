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

digestDate = null

if process.argv.length > 2
  digestDate = process.argv[2]
else
  digestDate = utils.getDateString()

winston.doInfo 'digestDate',
  digestDate: digestDate

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

    async.each users, createAndSendEventDigest, (error) ->
      callback error


createAndSendEventDigest = (user, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return

  winston.doInfo 'createAndSendEventDigest'

  select =
    userId: user._id
    digestDate: digestDate

  EventDigestModel.findOne select, (mongoError, eventDigest) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if eventDigest
      if eventDigest.hasBeenEmailed
        callback()
      else
        eventDigestHelpers.populateEvents eventDigest, (error) ->
          if error then callback error; return

          sendEventDigestEmail eventDigest, user, callback
    else
      eventDigestHelpers.buildAndSaveEventDigest user, digestDate, (error, eventDigest) ->
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