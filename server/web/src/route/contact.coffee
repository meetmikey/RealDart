commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston

ContactModel = require(commonAppDir + '/schema/contact').ContactModel
ObjectID = require(commonAppDir + '/lib/mongooseConnect').mongoose.Types.ObjectId
contactHelpers = require commonAppDir + '/lib/contactHelpers'

routeUtils = require '../lib/routeUtils'

routeContact = this


exports.getContacts = (req, res) ->
  unless req?.user then routeUtils.sendFail res; return

  select =
    userId: req.user._id

  ContactModel.find select, (mongoError, contacts) ->
    if mongoError then winston.doMongoError mongoError, {}, res; return

    contacts = contacts || []
    for contact, index of contacts
      contacts[index] = contactHelpers.sanitizeContact contact

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

    routeUtils.sendOK res,
      contact: contactHelpers.sanitizeContact contact