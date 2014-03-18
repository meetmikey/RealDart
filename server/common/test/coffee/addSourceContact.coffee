commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

ContactModel = require(commonAppDir + '/schema/contact').ContactModel
SourceContactModel = require(commonAppDir + '/schema/contact').SourceContactModel
winston = require(commonAppDir + '/lib/winstonWrapper').winston
utils = require commonAppDir + '/lib/utils'
emailUtils = require commonAppDir + '/lib/emailUtils'
contactHelpers = require commonAppDir + '/lib/contactHelpers'
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

run = (callback) ->

  firstName = 'Justin'
  lastName = 'Durack'
  emailAddress = 'justin@getrealkick.com'
  userId = '52f706661edc38e84c397b2a'
  liUserId = 'kN9wC_VznU'
  contactSource = constants.contactSource.LINKED_IN

  sourceContactData =
    _id: liUserId
    emailAddress: emailAddress
    emails: [emailAddress]
    firstName: firstName
    lastName: lastName

  contactHelpers.addSourceContact userId, contactSource, sourceContactData, callback
  #addSourceContactManually userId, contactSource, sourceContactData, callback


addSourceContactManually = (userId, contactSource, sourceContactData, callback) ->

  sourceContact = new SourceContactModel
    userId: userId
    sources: [contactSource]
    images: []

  sourceContact.liUserId = sourceContactData._id
  if sourceContactData.emailAddress
    sourceContact.primaryEmail = emailUtils.normalizeEmailAddress sourceContactData.emailAddress
    sourceContact.emails = emailUtils.normalizeEmailAddressArray [sourceContactData.emailAddress]
  sourceContact.firstName = sourceContactData.firstName
  sourceContact.lastName = sourceContactData.lastName


  sourceContact2 =
    userId: sourceContact.userId
    sources: sourceContact.sources
    images: sourceContact.images
    liUserId: sourceContact.liUserId
    primaryEmail: sourceContact.primaryEmail
    emails: sourceContact.emails
    firstName: sourceContact.firstName
    lastName: sourceContact.lastName

  sourceContact = sourceContact2

  select =
    userId: userId
    sources:
      $in: sourceContact.sources

  update =
    $set: sourceContact

  options =
    upsert: true

  winston.doInfo 'addSourceContact',
    select: select
    update: update

  SourceContactModel.findOneAndUpdate select, update, options, (mongoError) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    callback()


appInitUtils.initApp 'addSourceContact', initActions, run