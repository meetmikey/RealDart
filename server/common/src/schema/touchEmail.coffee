mongoose = require 'mongoose'
Schema = mongoose.Schema

TouchEmail = new Schema
  userId: {type: Schema.ObjectId}
  toEmail: {type: String}
  emailSubject: {type: String}
  numEmailAddressesOnThread: {type: Number}
  emailDateTime: {type: Date}

mongoose.model 'TouchEmail', TouchEmail
exports.TouchEmailModel = mongoose.model 'TouchEmail'