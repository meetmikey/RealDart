mongoose = require 'mongoose'
Schema = mongoose.Schema

UserOnboarding = new Schema
  userId: {type: Schema.ObjectId}
  fbAuthed: {type : Boolean, default : false}
  fbProfileScraped : {type : Boolean, default : false}
  fbFriendsScraped : {type : Boolean, default : false}
  fbFriendsIdsSaved : {type : Boolean, default : false}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'UserOnboarding', UserOnboarding
exports.UserOnboardingModel = mongoose.model 'UserOnboarding'