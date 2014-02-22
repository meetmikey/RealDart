mongoose = require 'mongoose'
Schema = mongoose.Schema

Contact = new Schema
  #This is the userId of the person whose contact this is.
  userId: {type: Schema.ObjectId}
  googleUserId: {type: String} #Optional: if it's a google contact, let's also save the googleUserId

  #All other fields relate to the contact himself/herself
  googleContactId: {type: Schema.ObjectId}
  fbUserId: {type: Number}
  liUserId: {type: String}
  primaryEmail: {type: String} #normalized email
  emails: {type: [String]} #normalized email(s)
  firstName: {type: String}
  middleName: {type: String}
  lastName: {type: String}
  picURL: {type: String}

  timestamp: {type: Date, default: Date.now}

Contact.index {userId: 1, emails: 1}, {sparse: 1}
Contact.index {userId: 1, lastName: 1}, {sparse: 1}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'