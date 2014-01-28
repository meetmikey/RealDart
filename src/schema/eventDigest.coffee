mongoose = require 'mongoose'
Schema = mongoose.Schema

EventDigest = new Schema
  userId: {type: Schema.ObjectId}
  eventIds: {type: [Schema.ObjectId]}
  digestDate: {type: Date, default: Date.now}
  hasBeenEmailed: {type: Boolean}
  timestamp: {type: Date, default: Date.now}

  events: {type: [String]} #DUMMY (do not save).

mongoose.model 'EventDigest', EventDigest
exports.EventDigestModel = mongoose.model 'EventDigest'