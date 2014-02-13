mongoose = require 'mongoose'
Schema = mongoose.Schema

Contact = new Schema
  userId: {type: Schema.ObjectId}
  fbUserId: {type: Schema.ObjectId}
  liUserId: {type: Schema.ObjectId}
  timestamp: {type: Date, default: Date.now}

Contact.index {userId: 1}, {background: 1}
Contact.index {userId: 1, fbUserId: 1}, {unique: true, sparse: true}
Contact.index {userId: 1, liUserId: 1}, {unique: true, sparse: true}

mongoose.model 'Contact', Contact
exports.ContactModel = mongoose.model 'Contact'