homeDir = process.env['REAL_DART_HOME']

graph = require 'fbgraph'
winston = require('./winstonWrapper').winston
FBUserModel = require(homeDir + '/schema/fbUser').FBUserModel
conf = require homeDir + '/conf'

fbHelpers = this

# parse the raw fql response and extract friend data
exports.getFriendsFromFQLResponse = (fqlResponse) =>
  if fqlResponse?.length
    fqlResponse.forEach (responseItem) ->
      if responseItem.name == 'friends'
        friends = responseItem.fql_result_set
        friends

# given a user object, get the json for updating mongo
exports.getUpdateJSONForUser = (userData) =>
  updateJSON = {'$set' : {}}
  for k, v of userData
    if k != '_id'
      updateJSON['$set'][k] = v
  updateJSON


# get data on a user's friends and save it to the database
exports.fetchAndSaveFriendData = (fbUser, callback) =>
  query =
    friends: 'SELECT uid, name, birthday FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())'

  graph.setAccessToken fbUser.accessToken

  graph.fql query, (err, res) ->
    winston.doInfo 'FB graph query response',
      res: res