mongoose = require 'mongoose'
Schema = mongoose.Schema

FBLocation =
  id: {type: String}
  name: {type: String}

FBUser = new Schema
  id: {type: String, required: true}
  name: {type: String}
  first_name: {type: String}
  last_name: {type: String}
  link: {type: String}
  hometown: {type: FBLocation}
  location: {type: FBLocation}
  #favorite_athletes: [ [Object] ], 
  #education: [ [Object], [Object], [Object], [Object] ],
  gender: {type: String, enum: ['male', 'female']}
  timezone: {type: Number}
  locale: {type: String}
  verified: {type : Boolean}
  updated_time: {type: String}
  username: {type: String}

mongoose.model 'FBUser', FBUser
exports.FBUserModel = mongoose.model 'FBUser'