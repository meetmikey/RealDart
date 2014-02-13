mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

LIUserName =
  familyName: {type: String}
  givenName: {type: String}

LIUser = new Schema
  _id: {type: String, required: true, unique: true}

  #tokens
  accessTokenEncrypted: {type: String}
  accessTokenSalt: {type: String}
  refreshTokenEncrypted: {type: String}
  refreshTokenSalt: {type: String}
  
  displayName: {type: String}
  name: {type: LIUserName}

LIUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenSalt = encryptedInfo.salt

LIUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenSalt
  decrypted

LIUser.virtual('refreshToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.refreshTokenEncrypted = encryptedInfo.encrypted
  this.refreshTokenSalt = encryptedInfo.salt

LIUser.virtual('refreshToken').get () ->
  decrypted = utils.decryptSymmetric this.refreshTokenEncrypted, this.refreshTokenSalt
  decrypted

mongoose.model 'LIUser', LIUser
exports.LIUserModel = mongoose.model 'LIUser'