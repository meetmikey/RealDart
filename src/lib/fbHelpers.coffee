appDir = process.env['REAL_DART_HOME'] + '/app'

graph = require 'fbgraph'
winston = require('./winstonWrapper').winston
FBUserModel = require(appDir + '/schema/fbUser').FBUserModel
async = require 'async'
conf = require appDir + '/conf'
_ = require 'underscore'

fbHelpers = this

# parse the raw fql response and extract friend data
exports.getFriendsFromFQLResponse = (fqlResponse) ->
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
exports.getUpdateJSONForUser = (userData) ->
  updateJSON = {'$set' : {}}
  for k, v of userData
    if k != '_id'
      updateJSON['$set'][k] = v
  updateJSON


# get data on a user's friends and save it to the database
exports.fetchAndSaveFriendData = (fbUser, callback) ->
  winston.doInfo 'fetchAndSaveFriendData'

  query =
    friends: 'SELECT 
      about_me, 
      activities, 
      age_range, 
      birthday_date,
      birthday,
      current_location,
      education,
      email,
      favorite_athletes,
      favorite_teams,
      first_name,
      hometown_location,
      last_name,
      middle_name,
      name,
      pic,
      political,
      profile_update_time,
      profile_url,
      relationship_status,
      religion,
      sex,
      significant_other_id,
      sports,
      tv,
      uid, 
      wall_count,
      website,
      quotes,
      work FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())'

  graph.setAccessToken fbUser.accessToken

  graph.fql query, (err, res) ->
    if err then callback winston.makeError err; return

    friends = fbHelpers.getFriendsFromFQLResponse (res.data)
    fbHelpers.saveFriendData(fbUser, friends, callback)

# save data in two places...
# _id's saved on original user, full data stored in individual fbUser objects
exports.saveFriendData = (fbUser, friends, callback) ->
  winston.doInfo 'saveFriendData'
  friendsClean = fbHelpers.removeNullFields friends

  async.series([
    (asyncCb) ->
      FBUserModel.collection.insert friendsClean, (err) ->
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


exports.removeNullFields = (friends) =>
  friends?.forEach (friend) ->
    for key, val of friend
      #remove null keys
      if val == null
        delete friend[key]
      #remove empty strings or arrays
      else if val?.length == 0
        delete friend[key]

  friends

exports.getFacebookFriends = (user, callback) ->
  unless user then callback winston.makeMissingParamError 'user'; return
  unless user.fbUserId then callback winston.makeMissingParamError 'user.fbUserId'; return

  winston.doInfo 'getFacebookFriends'

  FBUserModel.findById user.fbUserId, (mongoError, fbUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if not fbUser
      winston.doWarn 'no fbUser',
        fbUserId: user.fbUserId
      callback()
    else if not fbUser.friends
      winston.doWarn 'no friends',
        fbUserId: user.fbUserId
      callback()
    else
      friendsSelect =
        _id:
          $in: fbUser.friends

      #winston.doInfo 'friendsSelect',
      #  friendsSelect: friendsSelect

      FBUserModel.find friendsSelect, (mongoError, fbFriends) ->
        if mongoError then callback winston.makeMongoError mongoError; return

        callback null, fbFriends

exports.getPrintableName = (fbUser) ->
  if fbUser.first_name and fbUser.last_name
    return fbUser.first_name + ' ' + fbUser.last_name
  if fbUser.first_name
    return fbUser.first_name
  if fbUser.last_name
    return 'M. ' + fbUser.last_name
  return ''