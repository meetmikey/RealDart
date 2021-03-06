commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
appInitUtils = require commonAppDir + '/lib/appInitUtils'
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
commonConstants = require commonAppDir + '/constants'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]


run = (callback) ->

  liUserId = getLIUserId()
  unless liUserId then callback winston.makeMissingParamError 'liUserId'; return

  LIUserModel.findById liUserId, (mongoError, liUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless liUser
      winston.doInfo 'no liUser found',
        liUserId: liUserId
    else
      console.log 'liUser',
        liUser: liUser
        token: liUser.token
        tokenSecret: liUser.tokenSecret

    callback()


getLIUserId = () ->
  if process.argv.length < 3
    winston.doError 'missing input'
    winston.doInfo 'usage: node getLIUser.js <liUserId>'
    process.exit 1

  liUserId = process.argv[2]
  liUserId


appInitUtils.initApp 'getLIUser', initActions, run