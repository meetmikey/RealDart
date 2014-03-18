mongoose = require 'mongoose'
Schema = mongoose.Schema
Location = require('./location').LocationSchema

utils = require '../lib/utils'

GoogleContactAddress = new Schema
  formattedAddress : {type : String}
  city : {type : String}
  street : {type : String}
  region : {type : String}
  postcode : {type : String}
  location : {type : [Location], default : []} # mongoose limitation, subdocs must be arrays

GoogleContactWebsite = new Schema
  href : {type : String}
  rel : {type : String}

GoogleContactPhoneNumber = new Schema
  number : {type : String}
  type : {type : String}
  location : {type : [Location], default : []} # mongoose limitation, subdocs must be arrays

GoogleContactPhoneNumber.path('location').validate (v) ->
  v.length < 2

GoogleContactAddress.path('location').validate (v) ->
  v.length < 2

GoogleContact = new Schema
  googleContactId : {type : String}
  groupIds : {type : String}
  isMyContact : {type : Boolean}
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
  timestamp: {type: Date, default: Date.now}


GoogleContact.index {userId: 1, emails: 1}, {sparse: true}
GoogleContact.index {userId: 1, googleContactId: 1}, {unique: true}

mongoose.model 'GoogleContact', GoogleContact
exports.GoogleContactModel = mongoose.model 'GoogleContact'