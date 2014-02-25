commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
workerAppDir = commonAppDir + '/../../worker/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
winston = require( commonAppDir + '/lib/winstonWrapper' ).winston
mongoose = require( commonAppDir + '/lib/mongooseConnect' ).mongoose
UserModel = require( commonAppDir + '/schema/user' ).UserModel
GoogleUserModel = require( commonAppDir + '/schema/googleUser' ).GoogleUserModel

commonConstants = require commonAppDir + '/constants'

mailDownloadHelpers = require workerAppDir + '/lib/mailDownloadHelpers'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

minUID = 1
maxUID = minUID + commonConstants.HEADER_BATCH_SIZE - 1
#maxUID = 30

mailHeaderDownloadJob = 
  userId: '52f706661edc38e84c397b2a'
  googleUserId: '115242422353146010856'
  uidBatch:
    minUID: minUID
    maxUID: maxUID
  

run = (callback) ->
  mailDownloadHelpers.doMailHeaderDownloadJob mailHeaderDownloadJob, callback

postInit = () ->
  run (error) ->
    if error then winston.handleError error
    mongoose.disconnect()
    winston.doInfo 'Done.'

appInitUtils.initApp 'doMailHeaderDownloadJob', initActions, postInit