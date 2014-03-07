mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

GoogleContactAddress = new Schema
  formattedAddress : {type : String}
  city : {type : String}
  street : {type : String}
  region : {type : String}
  postcode : {type : String}

GoogleContactWebsite = new Schema
  href : {type : String}
  rel : {type : String}

GoogleContactPhoneNumber = new Schema
  number : {type : String}
  type : {type : String}

GoogleContact = new Schema
  contactId : {type : String}
  groupIds : {type : String}
  userId: Schema.ObjectId
  googleUserId: {type: String}
  primaryEmail: {type: String}
  emails: {type: [String]}
  title: {type: String} # Straight from the google contact title field.
  firstName: {type: String}
  middleName: {type: String}
  lastName: {type: String}
  phoneNumbers : {type : [GoogleContactPhoneNumber]}
  birthday : {type : String}
  websites : {type : [GoogleContactWebsite]}
  addresses : {type : [GoogleContactAddress]}

GoogleContact.index {userId: 1, emails: 1}, {sparse: true}
GoogleContact.index {userId: 1, contactId: 1}, {unique: true}

mongoose.model 'GoogleContact', GoogleContact
exports.GoogleContactModel = mongoose.model 'GoogleContact'