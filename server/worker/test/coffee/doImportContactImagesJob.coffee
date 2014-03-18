commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
workerAppDir = commonAppDir + '/../../worker/app'

appInitUtils = require commonAppDir + '/lib/appInitUtils'

commonConstants = require commonAppDir + '/constants'

cleanupContactHelpers = require workerAppDir + '/lib/cleanupContactHelpers'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

job = 
  userId: '52f706661edc38e84c397b2a'
  
run = (callback) ->
  cleanupContactHelpers.doImportContactImagesJob job, callback


appInitUtils.initApp 'doImportContactImagesJob', initActions, run