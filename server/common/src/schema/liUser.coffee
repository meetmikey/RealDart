mongoose = require 'mongoose'
Schema = mongoose.Schema

LIUserName =
  familyName: {type: String}
  givenName: {type: String}

LIUser = new Schema
  _id: {type: String, required: true, unique: true}
  token: {type: String}
  tokenSecret: {type: String}
  displayName: {type: String}
  name: {type: LIUserName}


mongoose.model 'LIUser', LIUser
exports.LIUserModel = mongoose.model 'LIUser'