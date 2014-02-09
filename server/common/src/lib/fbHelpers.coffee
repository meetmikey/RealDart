commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'
graph = require 'fbgraph'
_ = require 'underscore'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
commonConf = require commonAppDir + '/conf'

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

exports.getUserJSONFromProfile = (profile) ->
  userJSON = {}
  omitKeys = [
    '_id'
    '_raw'
    '_json'
  ]
  for key, value of profile
    if omitKeys.indexOf( key ) isnt -1
      continue
    else
      userJSON[key] = value
  userJSON


# exchange short-lived access token for long-lived (60 day) token
exports.extendToken = (accessToken, cb) ->
  graph.extendAccessToken {
    "access_token" : accessToken
    "client_id" : commonConf.fb.app_id
    "client_secret" : commonConf.fb.app_secret
  }, (err, facebookRes) ->
      if err
        cb winston.makeError(err)
      else
        cb null, facebookRes

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


exports.fetchFQLDataForSelf = (fbUser, callback) ->
  winston.doInfo 'fetchAndSaveFriendData'

  query =
    me: 'SELECT 
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
      work FROM user WHERE uid me()'

  graph.setAccessToken fbUser.accessToken

  graph.fql query, (err, res) ->
    if err then callback winston.makeError err; return

    #TODO: do something with the data
    console.log res
    callback null, res

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
      fbUser.friends = _.pluck friends, '_id'
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
