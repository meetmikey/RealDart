mongoose = require 'mongoose'
Schema = mongoose.Schema

PhoneNumber = new Schema
  number : {type : String}
  type : {type : String}
  { _id : false }

Location = new Schema
  lat : Number
  lng : Number
  city : String
  state : String
  country : {type : String, default : 'United States'}
  readableLocation : String
  source : {type : String, enum : ['area_code', 'zip', 'address', 'facebook_current_location', 'linkedin_location']}
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
  imageS3Filenames: {type: [String]}
  isMyContactForGoogle : {type : Boolean}
  phoneNumbers : {type : [PhoneNumber]}
  locations : {type : [Location]}
  timestamp: {type: Date, default: Date.now}

  #DUMMIES
  numTouches: {}

  # Double purpose...
  #  Temporary storage for imageURLs (before we import them into s3)
  #  And signedURLs of images when we are about to display them
  imageURLs: {}

Contact.index {userId: 1, emails: 1}, {sparse: 1}
Contact.index {userId: 1, lastNameLower: 1}, {sparse: 1}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'