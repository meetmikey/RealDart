mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

GoogleUserName =
  familyName: {type: String}
  givenName: {type: String}

GoogleUser = new Schema
  _id: {type: String, required: true, unique: true}

  #tokens
  accessTokenEncrypted: {type: String}
  accessTokenSalt: {type: String}
  refreshTokenEncrypted: {type: String}
  refreshTokenSalt: {type: String}

  displayName: {type: String}
  name: {type: GoogleUserName}
  emails: {type: [String]}


GoogleUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenSalt = encryptedInfo.salt

GoogleUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenSalt
  decrypted


GoogleUser.virtual('refreshToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.refreshTokenEncrypted = encryptedInfo.encrypted
  this.refreshTokenSalt = encryptedInfo.salt

GoogleUser.virtual('refreshToken').get () ->
  decrypted = utils.decryptSymmetric this.refreshTokenEncrypted, this.refreshTokenSalt
  decrypted

mongoose.model 'GoogleUser', GoogleUser
exports.GoogleUserModel = mongoose.model 'GoogleUser'