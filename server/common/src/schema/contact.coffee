mongoose = require 'mongoose'
Schema = mongoose.Schema

Contact = new Schema
  #This is the userId of the person whose contact this is.
  userId: {type: Schema.ObjectId}

  #All other fields relate to the contact himself/herself
  fbUserId: {type: Number}
  liUserId: {type: Number}
  timestamp: {type: Date, default: Date.now}

Contact.index {userId: 1}, {background: 1}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'