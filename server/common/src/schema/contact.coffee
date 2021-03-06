mongoose = require 'mongoose'
Schema = mongoose.Schema
Location = require('./location').LocationSchema

PhoneNumber = new Schema
  number : {type : String}
  type : {type : String}
  { _id : false }

ImageInfo = new Schema
  sourceURL: {type: String}
  s3Filename: {type: String}

Contact = new Schema
  userId: {type: Schema.ObjectId} # userId of the person whose contact this is
  googleUserId: {type: String} # Optional: if it's a google contact, let's also save the googleUserId

  # All other fields relate to the contact himself/herself
  googleContactId: {type: Schema.ObjectId}
  fbUserId: {type: Number}
  liUserId: {type: String}
  primaryEmail: {type: String} # normalized email
  emails: {type: [String]} # normalized email(s)
  firstName: {type: String}
  firstNameLower: {type: String}
  middleName: {type: String}
  middleNameLower: {type: String}
  lastName: {type: String}
  lastNameLower: {type: String}
  images: {type: [ImageInfo]}
  phoneNumbers : {type : [PhoneNumber]}
  locations : {type : [Location]}
  sources: {type: [String]}
  # For SourceContacts, this is the single Contact that this source contributed to.
  # For Contacts, this is one or more SourceContacts that contributed to it.
  mappedContacts: {type: [Schema.ObjectId]}
  timestamp: {type: Date, default: Date.now}

  # DUMMIES
  #############
  numTouches: {}
  imageURLs: {} # signed urls of images when we are about to display them

Contact.index {userId: 1, emails: 1}, {sparse: 1}
Contact.index {userId: 1, lastNameLower: 1}, {sparse: 1}
Contact.index {userId: 1, sources: 1, googleContactId: 1, fbUserId: 1, liUserId: 1, primaryEmail: 1}, {sparse: 1}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'

mongoose.model 'SourceContact', Contact
exports.SourceContactModel = mongoose.model 'SourceContact'
