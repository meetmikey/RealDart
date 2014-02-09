mongoose = require 'mongoose'
Schema = mongoose.Schema

User = new Schema
  firstName: {type: String}
  lastName: {type: String}
  email: {type: String}
  passwordHash: {type: String}
  passwordResetCode: {type: String}
  personId: {type: Schema.ObjectId}
  fbUserId : {type: Number}
  liUserId : {type: String}
  timestamp: {type: Date, default: Date.now}

User.index({email: 1}, {unique : true})
User.index({fbUserId: 1}, {unique: true, sparse: true})

mongoose.model 'User', User
exports.UserModel = mongoose.model 'User'