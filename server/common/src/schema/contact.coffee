mongoose = require 'mongoose'
Schema = mongoose.Schema

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
  images: {type: [String]}

  timestamp: {type: Date, default: Date.now}

  #DUMMIES
  numTouches: {type: Number}
  imageURLs: {type: [String]} # temporary storage for imageURLs (before we import them into s3)

Contact.index {userId: 1, emails: 1}, {sparse: 1}
Contact.index {userId: 1, lastNameLower: 1}, {sparse: 1}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'