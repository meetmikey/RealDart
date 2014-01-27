mongoose = require 'mongoose'
Schema = mongoose.Schema

User = new Schema
  personId: {type: Schema.ObjectId}
  firstName: {type: String}
  lastName: {type: String}
  fbUserId : {type : Schema.ObjectId}
  lnkdUserId : {type : Schema.ObjectId}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'User', User
exports.UserModel = mongoose.model 'User'