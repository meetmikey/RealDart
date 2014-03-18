mongoose = require 'mongoose'
Schema = mongoose.Schema

Location = new Schema
  lat : Number
  lng : Number
  streetAddress : String
  city : String
  state : String
  country : {type : String, default : 'United States'}
  zip : {type : String}
  readableLocation : String
  locationType : {type : String, enum : ['ROOFTOP', 'RANGE_INTERPOLATED', 'GEOMETRIC_CENTER', 'APPROXIMATE']}
  source : {type : String, enum : ['google_phone', 'google_address', 'facebook_current_location', 'linkedin_location']}
  {_id : false}

exports.LocationSchema = Location


GeocodeCache = new Schema
  _id : {type : String}
  response : {type : String}

mongoose.model 'GeocodeCache', GeocodeCache
exports.GeocodeCacheModel = mongoose.model 'GeocodeCache'