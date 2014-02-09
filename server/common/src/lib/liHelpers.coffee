commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'
graph = require 'fbgraph'
_ = require 'underscore'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
commonConf = require commonAppDir + '/conf'

liHelpers = this

# given a user object, get the json for updating mongo
exports.getUpdateJSONForUser = (userData) ->
  updateJSON = {'$set' : {}}
  for k, v of userData
    if k != '_id'
      updateJSON['$set'][k] = v
  updateJSON