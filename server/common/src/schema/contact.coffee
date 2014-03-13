mongoose = require 'mongoose'
Schema = mongoose.Schema

PhoneNumber = new Schema
  number : {type : String}
  type : {type : String}
  { _id : false }

Location = new Schema
  lat : Number
  lng : Number
  streetAddress : String
  city : String
  state : String
  country : {type : String, default : 'United States'}
  zip : {type : String}
  readableLocation : String
  locationType : {type : String, enum : ['ROOFTOP', 'RANGE_INTERPOLATED', 'GEOMETRIC_CENTER', 'APPROXIMATE']}
  source : {type : String, enum : ['google_phone', 'google_address', 'facebook_current_location', 'linkedin_location']}
  {_id : false}

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
  imageSourceURLs: {type: [String]}
  imageS3Filenames: {type: [String]}
  isMyContactForGoogle : {type : Boolean}
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

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'

mongoose.model 'SourceContact', Contact
exports.SourceContactModel = mongoose.model 'SourceContact'
