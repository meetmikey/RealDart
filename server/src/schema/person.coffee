mongoose = require 'mongoose'
Schema = mongoose.Schema

Person = new Schema
  firstName: {type: String}
  lastName: {type: String}
  fbUserId: {type: Schema.ObjectId}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'Person', User
exports.PersonModel = mongoose.model 'Person'