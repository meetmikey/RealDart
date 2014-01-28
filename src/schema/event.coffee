constants = require '../constants'

mongoose = require 'mongoose'
Schema = mongoose.Schema

eventTypes = []
for eventType of constants.EVENT_TYPE
  eventTypes.push eventType

Event = new Schema
  userId: {type: Schema.ObjectId, required: true}
  fbUserId: {type: Schema.ObjectId}
  type: {type: String, enum: eventTypes}
  timestamp: {type: Date, default: Date.now}

  fbUser: {type: String} #DUMMY (do not save).

mongoose.model 'Event', Event
exports.EventModel = mongoose.model 'Event'