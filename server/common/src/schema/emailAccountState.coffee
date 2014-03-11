mongoose = require 'mongoose'
Schema = mongoose.Schema

EmailAccountStateUIDBatch =
  maxUID: {type: Number}
  minUID: {type: Number}

EmailAccountState = new Schema
  userId: {type: Schema.ObjectId}
  googleUserId: {type: String}
  accountType: {type:String, enum: ['google']}
  outstandingInitialUIDBatches: {type: [EmailAccountStateUIDBatch]}
  originalUIDNext: {type: Number}
  currentUIDNext: {type: Number}
  highestEmailIdForAddingTouches: {type: Schema.ObjectId}


EmailAccountState.index {userId: 1, googleUserId: 1}, {sparse: 1}


mongoose.model 'EmailAccountState', EmailAccountState
exports.EmailAccountStateModel = mongoose.model 'EmailAccountState'