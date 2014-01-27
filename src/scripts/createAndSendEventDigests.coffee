#!/usr/local/bin/node

winston = require('../lib/winstonWrapper').winston
appInitUtils = require '../lib/appInitUtils'
UserModel = require('../schema/user').UserModel


initActions = [
  appInitUtils.CONNECT_MONGO
]


run = (callback) ->
  select = {}

  UserModel.find select, (mongoError, users) ->
    if mongoError
      callback winston.makeMongoError mongoError
    else
      winston.doInfo 'got users: ',
        users: users


postInit = () ->

  run (error) ->
    if error
      winston.handleError error
    winston.doInfo 'Done.'

#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'CreateAndSendEventDigests', initActions, postInit