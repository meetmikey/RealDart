commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

async = require 'async'
graph = require 'fbgraph'
_ = require 'underscore'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
ContactModel = require(commonAppDir + '/schema/contact').ContactModel
commonConf = require commonAppDir + '/conf'

fbHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  profileJSON = profile?._json || {}

  userJSON = {}
  omitKeys = [
  ]
  for key, value of profileJSON
    if omitKeys.indexOf( key ) isnt -1
      continue
      
    if key is 'id'
      userJSON['_id'] = value
    else
      userJSON[key] = value
  userJSON

exports.doDataImportJob = (job, callback) ->
  unless job then callback winston.makeMissingParamError 'job'; return
  unless job.userId then callback winston.makeMissingParamError 'job.userId'; return
  unless job.fbUserId then callback winston.makeMissingParamError 'job.fbUserId'; return

  userId = job.userId
  fbUserId = job.fbUserId

  FBUserModel.findById fbUserId, (mongoError, fbUser) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    unless fbUser
      callback winston.makeError 'fbUser not found',
        fbUserId: fbUserId
      return

    fbHelpers.fetchAndSaveFriendData fbUser, (error) ->
      if error then callback error; return

      fbHelpers.addFriendsToContacts userId, fbUser, callback

exports.addFriendsToContacts = (userId, fbUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless fbUser then callback winston.makeMissingParamError 'fbUser'; return

  fields =
    friends: 1

  FBUserModel.findById fbUser._id, fields, (mongoError, result) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    friendIds = result?.friends

    winston.doInfo 'friendIds',
      friendIds: friendIds

    unless friendIds and friendIds.length then callback(); return

    async.each friendIds, (friendId, asyncCallback) ->
      fbHelpers.addContact userId, fbUser, friendId, asyncCallback
    , (error) ->
      callback error

exports.addContact = (userId, fbUser, friendId, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless fbUser then callback winston.makeMissingParamError 'fbUser'; return
  unless friendId then callback winston.makeMissingParamError 'friendId'; return

  contact = new ContactModel
    userId: userId
    fbUserId: friendId

  contact.save (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    callback()

# parse the raw fql response and extract friend data
exports.getFriendsFromFQLResponse = (fqlResponse) ->
  friends = []
  unless fqlResponse?.length then return friends

  fqlResponse.forEach (responseItem) ->
    if responseItem.name is 'friends'
      friends = responseItem.fql_result_set
      friends.forEach (friend) ->
        friend._id = friend.uid
        delete friend['uid']

  friends

# exchange short-lived access token for long-lived (60 day) token
exports.extendToken = (accessToken, cb) ->
  graph.extendAccessToken
    access_token: accessToken
    client_id: commonConf.fb.app_id
    client_secret: commonConf.fb.app_secret
  , (err, facebookRes) ->
      if err
        cb winston.makeError err
      else
        cb null, facebookRes

# get data on a user's friends and save it to the database
exports.fetchAndSaveFriendData = (fbUser, callback) ->
  unless fbUser then callback winston.makeMissingParamError 'fbUser'; return

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

    friends = fbHelpers.getFriendsFromFQLResponse res.data
    fbHelpers.saveFriendData fbUser, friends, callback


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
  unless fbUser then return ''

  if fbUser.first_name and fbUser.last_name
    return fbUser.first_name + ' ' + fbUser.last_name
  if fbUser.first_name
    return fbUser.first_name
  if fbUser.last_name
    return 'M. ' + fbUser.last_name
  return ''
