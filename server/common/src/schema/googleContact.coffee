mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'


GoogleContact = new Schema
  userId: Schema.ObjectId
  googleUserId: {type: String}
  primaryEmail: {type: String}
  emails: {type: [String]}
  title: {type: String} # Straight from the google contact title field.
  firstName: {type: String}
  middleName: {type: String}
  lastName: {type: String}

GoogleContact.index {userId: 1, emails: 1}, {sparse: true}

mongoose.model 'GoogleContact', GoogleContact
exports.GoogleContactModel = mongoose.model 'GoogleContact'