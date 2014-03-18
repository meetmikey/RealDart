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

# Seems a little unnecessarily specific, but this is what our findOneAndModify wants
#  Mongo was throwing tons of log messages into /var/log/mongodb/mongodb.log without it.
#  See http://stackoverflow.com/questions/4758377/mongodb-geting-client-cursoryield-cant-unlock-b-c-of-recursive-lock-warnin
Touch.index {userId: 1, contactId: 1, emailId: 1, type: 1}, {sparse: true}

mongoose.model 'Touch', Touch
exports.TouchModel = mongoose.model 'Touch'