mongoose = require 'mongoose'
Schema = mongoose.Schema

Touch = new Schema
  userId: {type: Schema.ObjectId}
  contactId: {type: Schema.ObjectId}
  type: {type: String, enum: ['email']}
  emailSubject: {type: String}
  date: {type: Date}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'Touch', Touch
exports.TouchModel = mongoose.model 'Touch'