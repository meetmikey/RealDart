mongoose = require 'mongoose'
Schema = mongoose.Schema

FBLocation =
  id: {type: String}
  name: {type: String}


#TODO: remove mixed types!!
FBUser = new Schema
  _id: {type: Number, required: true, unique: true}
  accessToken : {type : String}
  age_range : {type : String}
  bio : {type : String}
  birthday: {type : String}
  birthday_date : {type : String}
  books : {type : String}
  cover : Schema.Types.Mixed
  education : Schema.Types.Mixed
  email : {type : String}
  favorite_athletes: Schema.Types.Mixed
  favorite_teams : Schema.Types.Mixed
  first_name: {type: String}
  gender: {type: String, enum: ['male', 'female']}
  hometown: {type: FBLocation}
  inspirational_people : Schema.Types.Mixed
  is_verified: {type : Boolean}
  languages : Schema.Types.Mixed
  last_name: {type: String}
  link: {type: String}
  locale: {type: String}
  location: {type: FBLocation}
  current_location : {type: FBLocation}
  hometown_location : {type: FBLocation}
  middle_name : {type : String}
  name: {type: String}
  name_format : {type : String}
  political : {type : String}
  quotes : {type : String}
  relationship_status : {type : String}
  religion : {type : String}
  significant_other : Schema.Types.Mixed
  third_party_id : {type : String}
  username: {type: String}
  verified: {type : Boolean}
  website : {type : String}
  work : Schema.Types.Mixed
  timezone: {type: Number}
  updated_time: {type: String}
  friends : {type : [Number], index : true}

mongoose.model 'FBUser', FBUser
exports.FBUserModel = mongoose.model 'FBUser'