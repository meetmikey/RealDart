commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
commonConstants = require commonAppDir + '/constants'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

postInit = () ->
  run (error) ->
    if error then winston.handleError error

    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

getFBUserId = () ->
  if process.argv.length < 3
    winston.doError 'missing input'
    winston.doInfo 'usage: node getFBUser.js <fbUserId>'
    process.exit 1

  fbUserId = process.argv[2]
  fbUserId

run = (callback) ->

  fbUserId = getFBUserId()
  unless fbUserId then callback winston.makeMissingParamError 'fbUserId'; return

  FBUserModel.findById fbUserId, (mongoError, fbUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless fbUser
      winston.doInfo 'no fbUser found',
        fbUserId: fbUserId
    else
      console.log 'fbUser',
        fbUser: fbUser
        accessToken: fbUser.accessToken
        refreshToken: fbUser.refreshToken

    callback()

#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'getFBUser', initActions, postInit