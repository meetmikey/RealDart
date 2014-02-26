commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston

ContactModel = require(commonAppDir + '/schema/contact').ContactModel
FBUserModel = require(commonAppDir + '/schema/fbUser').FBUserModel
LIUserModel = require(commonAppDir + '/schema/liUser').LIUserModel
ObjectID = require(commonAppDir + '/lib/mongooseConnect').mongoose.Types.ObjectId
contactHelpers = require commonAppDir + '/lib/contactHelpers'

routeUtils = require '../lib/routeUtils'

routeContact = this


exports.getContacts = (req, res) ->
  unless req?.user then routeUtils.sendFail res; return

  contactHelpers.getAllContactsWithTouchCounts req.user._id, (error, contacts) ->
    if error then winston.handleError error, res; return

    routeUtils.sendOK res,
      contacts: contacts


exports.getContact = (req, res) ->
  unless req?.user then routeUtils.sendFail res; return
  unless req?.params?.contactId then routeUtils.sendFail res; return

  try
    contactIdObjectId = new ObjectID req.params.contactId
  catch exception
    routeUtils.sendFail res, 'invalid contactId'
    return

  select =
    _id: contactIdObjectId
    userId: req.user._id

  ContactModel.findOne select, (mongoError, contact) ->
    if mongoError then winston.doMongoError mongoError, {}, res; return

    contact = contactHelpers.sanitizeContact contact

    getFBUser = (fbUserId, cb) ->
      unless fbUserId then cb(); return
      FBUserModel.findById fbUserId, (mongoError, fbUser) ->
        if mongoError then cb winston.makeMongoError mongoError; return
        cb null, fbUser

    getLIUser = (liUserId, cb) ->
      unless liUserId then cb(); return
      LIUserModel.findById liUserId, (mongoError, liUser) ->
        if mongoError then cb winston.makeMongoError mongoError; return
        cb null, liUser

    getFBUser contact.fbUserId, (error, fbUser) ->
      if error then winston.handleError error, res; return

      getLIUser contact.liUserId, (error, liUser) ->
        if error then winston.handleError error, res; return

        routeUtils.sendOK res,
          contact: contact
          fbUser: fbUser
          liUser: liUser