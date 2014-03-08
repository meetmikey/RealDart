commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

contactHelpers = require commonAppDir + '/lib/contactHelpers'
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

userId = '52f706661edc38e84c397b2a'

run = (callback) ->
  contactHelpers.getAllContactsWithTouchCounts userId, (error, contacts) ->
    if error then callback error; return

    firstContact = null
    if contacts.length
      firstContact = contacts[0]

    callback()
  

appInitUtils.initApp 'contactTouchesMapReduce', initActions, run