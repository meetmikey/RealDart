mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

#TODO: remove mixed types!
LIUser = new Schema
  _id: {type: String, required: true, unique: true}

  #tokens
  accessTokenEncrypted: {type: String}
  accessTokenIV: {type: String}
  
  #profile data
  educations: Schema.Types.Mixed
  emailAddress: {type: String}
  firstName: {type: String}
  lastName: {type: String}
  formattedName: {type: String}
  following: Schema.Types.Mixed
  headline: {type: String}
  industry: {type: String}
  jobBookmarks: Schema.Types.Mixed
  location: Schema.Types.Mixed
  numConnections: {type: Number}
  pictureUrl: {type: String}
  positions: Schema.Types.Mixed
  publicProfileUrl: {type: String}
  recommendationsReceived: Schema.Types.Mixed
  siteStandardProfileRequest: {type: String}
  skills: Schema.Types.Mixed
  specialties: {type: String}
  summary: {type: String}
  threeCurrentPositions: Schema.Types.Mixed
  threePastPositions: Schema.Types.Mixed


LIUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenIV = encryptedInfo.iv

LIUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenIV
  decrypted

mongoose.model 'LIUser', LIUser
exports.LIUserModel = mongoose.model 'LIUser'