mongoose = require 'mongoose'
constants = require '../constants'
Schema = mongoose.Schema

stateCodes = Object.keys(constants.US_STATE_CODES)

ZipCode = new Schema
  _id : {type : String, unique : true}
  lat : {type : Number}
  lng : {type : Number}
  state  : {type : String, enum : stateCodes}
  county : {type : String}
  city  : {type : String}

mongoose.model 'ZipCode', ZipCode
exports.ZipCodeModel = mongoose.model 'ZipCode'