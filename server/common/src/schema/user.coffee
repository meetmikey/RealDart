mongoose = require 'mongoose'
Schema = mongoose.Schema

User = new Schema
  firstName: {type: String}
  lastName: {type: String}
  email: {type: String}
  passwordHash: {type: String}
  passwordResetCode: {type: String}
  googleUserIds : {type: [String]}
  fbUserId : {type: Number}
  liUserId : {type: String}
  timestamp: {type: Date, default: Date.now}

User.index {email: 1}, {unique : true}

mongoose.model 'User', User
exports.UserModel = mongoose.model 'User'