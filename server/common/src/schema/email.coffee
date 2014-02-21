mongoose = require 'mongoose'
Schema = mongoose.Schema

Email = new Schema
  userId: {type: Schema.ObjectId}
  googleUserId: {type: String}
  uid: {type: String}
  messageId: {type: String}
  recipientEmails: {type: [String]}
  subject: {type: String}
  date: {type: Date}

mongoose.model 'Email', Email
exports.EmailModel = mongoose.model 'Email'