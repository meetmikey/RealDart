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
  timestamp: {type: Date, default: Date.now}

Email.index {userId: 1, googleUserId: 1, uid: 1}, {unique : true}

mongoose.model 'Email', Email
exports.EmailModel = mongoose.model 'Email'