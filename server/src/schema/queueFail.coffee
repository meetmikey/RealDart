mongoose = require('mongoose')
Schema   = mongoose.Schema;

QueueFail = new Schema
  queueName: {type: String}
  messageBody: {type : String}
  timestamp: {type: Date, default: Date.now}

mongoose.model 'QueueFail', QueueFail

QueueFailModel = mongoose.model 'QueueFail'
exports.QueueFailModel = QueueFailModel