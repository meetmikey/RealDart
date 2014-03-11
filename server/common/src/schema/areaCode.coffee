mongoose = require 'mongoose'
constants = require '../constants'
Schema = mongoose.Schema

stateCodes = Object.keys(constants.US_STATE_CODES)

AreaCode = new Schema
  _id : {type : String, unique : true}
  latitude : {type : Number}
  longitude : {type : Number}
  state  : {type : String, enum : stateCodes}
  majorCities  : {type : [String]}

mongoose.model 'AreaCode', AreaCode
exports.AreaCodeModel = mongoose.model 'AreaCode'