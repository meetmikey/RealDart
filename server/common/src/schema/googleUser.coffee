mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

GoogleContactGroup = new Schema
  systemGroupId : String,
  title : String,
  _id : {type : String, required : true}

GoogleUser = new Schema
  _id: {type: String, required: true, unique: true}

  #tokens
  accessTokenEncrypted: {type: String}
  accessTokenIV: {type: String}
  accessTokenExpiresAt: {type: Date}
  refreshTokenEncrypted: {type: String}
  refreshTokenIV: {type: String}

  email: {type: String}
  verified_email: {type: Boolean}
  name: {type: String}
  given_name: {type: String}
  family_name: {type: String}
  picture: {type: String}
  locale: {type: String}
  hd: {type: String}
  contactGroups  : {type : [GoogleContactGroup]}

  timestamp: {type: Date, default: Date.now}

GoogleUser.index {email: 1}, {unique : true}


GoogleUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenIV = encryptedInfo.iv

GoogleUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenIV
  decrypted


GoogleUser.virtual('refreshToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.refreshTokenEncrypted = encryptedInfo.encrypted
  this.refreshTokenIV = encryptedInfo.iv

GoogleUser.virtual('refreshToken').get () ->
  decrypted = utils.decryptSymmetric this.refreshTokenEncrypted, this.refreshTokenIV
  decrypted

mongoose.model 'GoogleUser', GoogleUser
exports.GoogleUserModel = mongoose.model 'GoogleUser'