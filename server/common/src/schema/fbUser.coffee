mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

FBLocation =
  id: {type: String}
  name: {type: String}

FBUserName =
  familyName: {type: String}
  givenName: {type: String}


#TODO: remove mixed types!!
FBUser = new Schema
  _id: {type: Number, required: true, unique: true}
  accessTokenEncrypted: {type: String}
  accessTokenSalt: {type: String}
  refreshTokenEncrypted: {type: String}
  refreshTokenSalt: {type: String}
  age_range : {type : String}
  bio : {type : String}
  birthday: {type : String}
  birthday_date : {type : String}
  books : {type : String}
  cover : Schema.Types.Mixed
  current_address : Schema.Types.Mixed
  education : Schema.Types.Mixed
  email : {type : String}
  favorite_athletes: Schema.Types.Mixed
  favorite_teams : Schema.Types.Mixed
  first_name: {type: String}
  gender: {type: String, enum: ['male', 'female']}
  hometown: {type: FBLocation}
  inspirational_people : Schema.Types.Mixed
  is_verified: {type : Boolean}
  languages : Schema.Types.Mixed
  last_name: {type: String}
  link: {type: String}
  locale: {type: String}
  location: {type: FBLocation}
  current_location : {type: FBLocation}
  hometown_location : {type: FBLocation}
  middle_name : {type : String}
  name: {type: FBUserName}
  name_format : {type : String}
  political : {type : String}
  quotes : {type : String}
  relationship_status : {type : String}
  religion : {type : String}
  significant_other : Schema.Types.Mixed
  third_party_id : {type : String}
  username: {type: String}
  verified: {type : Boolean}
  website : {type : String}
  work : Schema.Types.Mixed
  timezone: {type: Number}
  updated_time: {type: String}
  friends : {type : [Number], index : true}

FBUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenSalt = encryptedInfo.salt

FBUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenSalt
  decrypted


FBUser.virtual('refreshToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.refreshTokenEncrypted = encryptedInfo.encrypted
  this.refreshTokenSalt = encryptedInfo.salt

FBUser.virtual('refreshToken').get () ->
  decrypted = utils.decryptSymmetric this.refreshTokenEncrypted, this.refreshTokenSalt
  decrypted

mongoose.model 'FBUser', FBUser
exports.FBUserModel = mongoose.model 'FBUser'