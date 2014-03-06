async = require 'async'
fbgraph = require 'fbgraph'
_ = require 'underscore'

winston = require('./winstonWrapper').winston
FBUserModel = require('../schema/fbUser').FBUserModel
contactHelpers = require './contactHelpers'
sqsUtils = require './sqsUtils'
utils = require './utils'

conf = require '../conf'
constants = require '../constants'

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

    fbHelpers.fetchAndSaveFriendData userId, fbUser, (error) ->
      if error then callback error; return

      cleanupContactsJob =
        userId: userId
      
      sqsUtils.addJobToQueue conf.queue.cleanupContacts, cleanupContactsJob, callback

# get data on a user's friends and save it to the database
exports.fetchAndSaveFriendData = (userId, fbUser, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
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

  fbgraph.setAccessToken fbUser.accessToken

  fbgraph.fql query, (err, res) ->
    if err then callback winston.makeError err; return

    friends = fbHelpers.getFriendsFromFQLResponse res.data
    fbHelpers.saveFriendData userId, fbUser, friends, callback


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

# save data in two places...
# _id's saved on original user, full data stored in individual fbUser objects
exports.saveFriendData = (userId, fbUser, friends, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return

  winston.doInfo 'saveFriendData'

  for friend in friends
    utils.removeNullFields friend, true, true

  async.series([
    (seriesCallback) ->
      FBUserModel.collection.insert friends, (mongoError) ->
        if mongoError?.code is constants.MONGO_ERROR_CODE_DUPLICATE
          seriesCallback()
        else if mongoError
          seriesCallback winston.makeMongoError mongoError
        else
          seriesCallback()
    (seriesCallback) ->
      fbUser.friends = _.pluck friends, '_id'
      fbUser.save (mongoError)->
        if mongoError
          seriesCallback winston.makeMongoError mongoError
        else
          seriesCallback()
    (seriesCallback) ->
      async.each friends, (friend, eachCallback) ->
        contactHelpers.addContact userId, constants.service.FACEBOOK, friend, eachCallback
      , (error) ->
        seriesCallback error
    ]
    (error) ->
      callback error
  )

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

      FBUserModel.find friendsSelect, (mongoError, fbFriends) ->
        if mongoError then callback winston.makeMongoError mongoError; return

        callback null, fbFriends

exports.getImageURL = (fbUserId) ->
  unless fbUserId then return ''
  url = 'http://graph.facebook.com/' + fbUserId + '/picture?type=large'
  url

exports.getPrintableName = (fbUser) ->
  unless fbUser then return ''

  if fbUser.first_name and fbUser.last_name
    return fbUser.first_name + ' ' + fbUser.last_name
  if fbUser.first_name
    return fbUser.first_name
  if fbUser.last_name
    return 'M. ' + fbUser.last_name
  return ''

# exchange short-lived access token for long-lived (60 day) token
exports.extendToken = (accessToken, cb) ->
  fbgraph.extendAccessToken
    access_token: accessToken
    client_id: conf.fb.app_id
    client_secret: conf.fb.app_secret
  , (err, facebookRes) ->
      if err
        cb winston.makeError err
      else
        cb null, facebookRes