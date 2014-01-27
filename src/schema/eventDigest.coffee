mongoose = require 'mongoose'
Schema = mongoose.Schema

EventDigest = new Schema
  userId: {type: Schema.ObjectId}
  eventIds: {type: [Schema.ObjectId]}
  sentDate: {type: Date, default: Date.now}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'EventDigest', EventDigest
exports.EventDigestModel = mongoose.model 'EventDigest'