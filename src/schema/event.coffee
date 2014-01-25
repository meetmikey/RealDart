mongoose = require 'mongoose'
Schema = mongoose.Schema

Event = new Schema
  userId: {type: Schema.ObjectId, required: true}
  personId: {type: Schema.ObjectId, required: true}
  type: {type: String, enum: ['birthday']}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'Event', Event
exports.EventModel = mongoose.model 'Event'