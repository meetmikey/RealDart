commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

webUtils = require commonAppDir + '/lib/webUtils'
utils = require commonAppDir + '/lib/utils'
imageUtils = require commonAppDir + '/lib/imageUtils'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
ContactModel = require(commonAppDir + '/schema/contact').ContactModel

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

imageSourceURL = 'http://graph.facebook.com/7370/picture?type=large'
imageSourceURL = 'http://i.cdn.turner.com/cnn/.e/img/3.0/global/header/hdr-main.png'
contactId = '53273ed5e5e22cf91fc6d2e9'
numWebGets = 10

run = (callback) ->

  winston.doInfo 'running...'
  startTime = Date.now()

  count = 0
  interval = setInterval () ->
  
    ContactModel.findById contactId, (mongoError, contact) ->
      if mongoError then callback winston.makeMongoError mongoError; return
      unless contact then callback wiston.makeError 'no contact'; return

      imageUtils.importContactImage imageSourceURL, contact, (error) ->
        if error then callback error

        count++

        elapsedTime = Date.now() - startTime
        winston.doInfo 'done',
          elapsedTime: elapsedTime
          count: count

        if count >= numWebGets
          clearInterval interval
          interval = null
          callback()

  , 1000

  
###
    utils.runWithRetries webUtils.webGet, constants.DEFAULT_WEB_GET_ATTEMPTS
      , (error, response, url, responseHeaders) ->
        count++
        elapsedTime = Date.now() - startTime
        winston.doInfo 'got response',
          elapsedTime: elapsedTime
          count: count

        response.on 'data', () ->
          #winston.doInfo 'do nothing'
        
        if count >= numWebGets
          clearInterval interval
          interval = null
          callback()

      , imageSourceURL, false
###

appInitUtils.initApp 'slowWebGet', initActions, run