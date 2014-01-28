mongoose = require 'mongoose'
Schema = mongoose.Schema

User = new Schema
  personId: {type: Schema.ObjectId}
  firstName: {type: String}
  lastName: {type: String}
  fbUserId : {type : String}
  lnkdUserId : {type : String}
  timestamp: {type: Date, default: Date.now}

User.index({fbUserId : 1}, {unique : true, sparse: true})

mongoose.model 'User', User
exports.UserModel = mongoose.model 'User'