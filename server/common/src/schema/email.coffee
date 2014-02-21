mongoose = require 'mongoose'
Schema = mongoose.Schema

Recipient =
  email: {type: String}
  name: {type: String}

Email = new Schema
  userId: {type: Schema.ObjectId}
  googleUserId: {type: String}
  uid: {type: String}
  messageId: {type: String}
  recipients: {type: [Recipient]}
  subject: {type: String}
  date: {type: Date}

mongoose.model 'Email', Email
exports.EmailModel = mongoose.model 'Email'