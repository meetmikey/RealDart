mongoose = require 'mongoose'
Schema = mongoose.Schema

EventInteraction = new Schema
  userId: {type: Schema.ObjectId, required: true}
  eventId: {type: Schema.ObjectId, required: true}
  personId: {type: Schema.ObjectId, required: true}
  type: {type: String, enum: ['call','textMessage','fbMessage']}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'EventInteraction', EventInteraction
exports.EventInteractionModel = mongoose.model 'EventInteraction'