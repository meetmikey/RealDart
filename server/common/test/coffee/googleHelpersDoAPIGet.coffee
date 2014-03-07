commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

googleHelpers = require commonAppDir + '/lib/googleHelpers'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel


constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

userId = '102110918656901976675'

run = (callback) ->
  GoogleUserModel.findById(userId)
    .exec (err, googleUser) ->
      path = 'contacts/' + googleUser.email + '/full'
      queryParams =
        'start-index': 1
        'max-results': 50

      googleHelpers.doAPIGet googleUser, path, queryParams, (error, data) ->
        if error then callback error; return

        console.log data
        callback()


postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

appInitUtils.initApp 'googleHelpersDoAPIGet', initActions, postInit