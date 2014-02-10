commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
commonConf = require commonAppDir + '/conf'

liHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  userJSON = {}
  omitKeys = [
    '_json'
  ]
  for key, value of profile
    if omitKeys.indexOf( key ) isnt -1
      continue
    if key is 'id'
      userJSON['_id'] = value
    else
      userJSON[key] = value
  userJSON