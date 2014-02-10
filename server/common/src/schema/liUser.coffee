mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

LIUserName =
  familyName: {type: String}
  givenName: {type: String}

LIUser = new Schema
  _id: {type: String, required: true, unique: true}
  tokenEncrypted: {type: String}
  tokenSalt: {type: String}
  tokenSecretEncrypted: {type: String}
  tokenSecretSalt: {type: String}
  displayName: {type: String}
  name: {type: LIUserName}

LIUser.virtual('token').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.tokenEncrypted = encryptedInfo.encrypted
  this.tokenSalt = encryptedInfo.salt

LIUser.virtual('token').get () ->
  decrypted = utils.decryptSymmetric this.tokenEncrypted, this.tokenSalt
  decrypted

LIUser.virtual('tokenSecret').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.tokenSecretEncrypted = encryptedInfo.encrypted
  this.tokenSecretSalt = encryptedInfo.salt

LIUser.virtual('tokenSecret').get () ->
  decrypted = utils.decryptSymmetric this.tokenSecretEncrypted, this.tokenSecretSalt
  decrypted

mongoose.model 'LIUser', LIUser
exports.LIUserModel = mongoose.model 'LIUser'