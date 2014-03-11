mongoose = require 'mongoose'
Schema = mongoose.Schema

Touch = new Schema
  userId: {type: Schema.ObjectId}
  contactId: {type: Schema.ObjectId}
  type: {type: String, enum: ['email']}
  emailId: {type: Schema.ObjectId}
  emailSubject: {type: String}
  date: {type: Date}
  timestamp: {type: Date, default: Date.now}

Touch.index {userId: 1, contactId: 1}

mongoose.model 'Touch', Touch
exports.TouchModel = mongoose.model 'Touch'