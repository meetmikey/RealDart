commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
appInitUtils = require commonAppDir + '/lib/appInitUtils'
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
fbHelpers = require commonAppDir + '/lib/fbHelpers'
commonConstants = require commonAppDir + '/constants'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]


run = (callback) ->

  fbUserId = getFBUserId()
  unless fbUserId then callback winston.makeMissingParamError 'fbUserId'; return

  FBUserModel.findById fbUserId, (mongoError, fbUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless fbUser
      winston.doInfo 'no fbUser found',
        fbUserId: fbUserId
    else
      #winston.doInfo 'fbUser',
      #  fbUser: fbUser
      #  accessToken: fbUser.accessToken
      #  refreshToken: fbUser.refreshToken

      fbHelpers.addFriendsToContacts fbUser, callback

    #callback()


getFBUserId = () ->
  if process.argv.length < 3
    winston.doError 'missing input'
    winston.doInfo 'usage: node getFBUser.js <fbUserId>'
    process.exit 1

  fbUserId = process.argv[2]
  fbUserId


appInitUtils.initApp 'getFBUser', initActions, run