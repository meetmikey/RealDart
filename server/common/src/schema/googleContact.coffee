mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'


GoogleContact = new Schema
  _id: {type: String, required: true, unique: true}

  primaryEmail: {type: String}
  emails: {type: [String]}
  title: {type: String} # Straight from the google contact title field.
  firstName: {type: String}
  lastName: {type: String}

mongoose.model 'GoogleContact', GoogleContact
exports.GoogleContactModel = mongoose.model 'GoogleContact'