homeDir = process.env['REAL_DART_HOME']

graph = require 'fbgraph'
winston = require('./winstonWrapper').winston
FBUserModel = require(homeDir + '/schema/fbUser').FBUserModel
async = require 'async'
conf = require homeDir + '/conf'
_ = require 'underscore'

fbHelpers = this

# parse the raw fql response and extract friend data
exports.getFriendsFromFQLResponse = (fqlResponse) =>
  friends = []
  if fqlResponse?.length
    fqlResponse.forEach (responseItem) ->
      if responseItem.name == 'friends'
        friends = responseItem.fql_result_set
        friends.forEach (friend) ->
          friend._id = friend.uid
          delete friend['uid']

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

    friends = fbHelpers.getFriendsFromFQLResponse (res.data)
    fbHelpers.saveFriendData(fbUser, friends, callback)

# save data in two places...
# _id's saved on original user, full data stored in individual fbUser objects
exports.saveFriendData = (fbUser, friends, callback) =>

  async.series([
    (asyncCb) ->
      FBUserModel.collection.insert friends, (err) ->
        if err?.code ==11000
          asyncCb()
        else if err
          asyncCb winston.makeMongoError(err)
        else
          asyncCb()
    (asyncCb) ->
      fbUser.friends = _.pluck(friends, '_id')
      fbUser.save (err)->
        if err
          asyncCb winston.makeMongoError(err)
        else
          asyncCb()
    ]
    (err) ->
      callback err
  )