commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

ContactModel = require(commonAppDir + '/schema/contact').ContactModel
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
utils = require commonAppDir + '/lib/utils'
imageUtils = require commonAppDir + '/lib/imageUtils'
s3Utils = require commonAppDir + '/lib/s3Utils'
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

contactId = '530d312e323a3ec539b03f84'
imageURL = 'http://upload.wikimedia.org/wikipedia/en/f/f9/Monkey-gun.jpg'

run = (callback) ->
  ContactModel.findById contactId, (mongoError, contact) ->
    if mongoError then callback winston.makeMongoError mongoError; return
    unless contact then callback winston.makeError 'no contact'; return

    imageUtils.importContactImage imageURL, contact, (error, s3Filename) ->
      if error then callback error; return
      unless s3Filename then callback winston.makeError 'no s3Filename'; return

      s3Path = imageUtils.getContactImageS3Path s3Filename
      s3FullURL = s3Utils.signedURL s3Path, 'monkeyGun.jpg'
      winston.doInfo 'Imported.',
        s3FullURL: s3FullURL

      callback()

postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

appInitUtils.initApp 'importContactImage', initActions, postInit