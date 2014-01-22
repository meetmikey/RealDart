mongoose = require 'mongoose'
Schema = mongoose.Schema

FB_Location =
  id: {type: String}
  name: {type: String}

FB_User = new Schema
  id: {type: String, required: true}
  name: {type: String}
  first_name: {type: String}
  last_name: {type: String}
  link: {type: String}
  hometown: {type: FB_Location}
  location: {type: FB_Location}
  #favorite_athletes: [ [Object] ], 
  #education: [ [Object], [Object], [Object], [Object] ],
  gender: {type: String, enum: ['male', 'female']}
  timezone: {type: Number}
  locale: {type: String}
  verified: {type : Boolean}
  updated_time: {type: String}
  username: {type: String}

mongoose.model('FB_User', FB_User);
exports.FB_User_Model = mongoose.model('FB_User');