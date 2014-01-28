mongoose = require 'mongoose'
Schema = mongoose.Schema

EventDigest = new Schema
  userId: {type: Schema.ObjectId}
  eventIds: {type: [Schema.ObjectId]}
  digestDate: {type: String}
  hasBeenEmailed: {type: Boolean}
  timestamp: {type: Date, default: Date.now}

  events: {type: [String]} #DUMMY (do not save).


EventDigest.index { userId: 1, digestDate: 1 }, {unique : true}

mongoose.model 'EventDigest', EventDigest
exports.EventDigestModel = mongoose.model 'EventDigest'