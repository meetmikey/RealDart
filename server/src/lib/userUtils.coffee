bcrypt = require 'bcrypt'
winston = require('./winstonWrapper').winston
UserModel = require('../schema/user').UserModel

userUtils = this

exports.hashPassword = (password, callback) ->
  bcrypt.genSalt 10, (err, salt) ->
    if err then callback winston.makeError err; return

    bcrypt.hash password, salt, (err, hash) ->
      if err then callback winston.makeError err; return

      callback null, hash

exports.checkPassword = (input, comparisonHash, callback) ->
  bcrypt.compare inputHash, comparisonHash, (err, res) ->
    if err then callback winston.makeError err; return

    if res
      callback null, true
    else
      callback null, false

exports.registerUserRequest = (req, res) ->

  unless req and req.data then winston.doError 'invalid request', {}, res; return
  unless req.data.email then winston.doError 'invalid request', {}, res; return

  user = new UserModel
    email: req.data.email