mongoose = require 'mongoose'
Schema = mongoose.Schema


GoogleUserName =
  familyName: {type: String}
  givenName: {type: String}

GoogleUser = new Schema
  _id: {type: String, required: true, unique: true}
  displayName: {type: String}
  name: {type: GoogleUserName}
  emails: {type: [String]}


mongoose.model 'GoogleUser', GoogleUser
exports.GoogleUserModel = mongoose.model 'GoogleUser'