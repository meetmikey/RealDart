commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
commonConf = require commonAppDir + '/conf'

liHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  userJSON = {}
  omitKeys = [
    '_id'
    '_json'
  ]
  for key, value of profile
    if omitKeys.indexOf( key ) isnt -1
      continue
    else
      userJSON[key] = value
  userJSON