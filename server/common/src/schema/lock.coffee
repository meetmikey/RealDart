mongoose = require 'mongoose'
Schema = mongoose.Schema

constants = require '../constants'

Lock = new Schema
  key: {type: String, unique: true}
  createdAt: {type: Date, expires: constants.lock.EXPIRE_TIME_SECONDS}

mongoose.model 'Lock', Lock
exports.LockModel = mongoose.model 'Lock'