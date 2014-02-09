bcrypt = require 'bcrypt'

utils = require './utils'
winston = require('./winstonWrapper').winston
UserModel = require('../schema/user').UserModel

constants = require '../constants'

userUtils = this

exports.hashPassword = (password, callback) ->
  bcrypt.genSalt 10, (err, salt) ->
    if err then callback winston.makeError err; return

    bcrypt.hash password, salt, (err, hash) ->
      if err then callback winston.makeError err; return

      callback null, hash

exports.checkPassword = (input, comparisonHash, callback) ->
  bcrypt.compare input, comparisonHash, (err, res) ->
    if err then callback winston.makeError err; return

    if res
      callback null, true
    else
      callback null, false


exports.generatePasswordResetCode = (callback) ->
  rand = Math.random()
  date = Date.now()
  seedString = rand.toString() + date.toString()

  bcrypt.genSalt 10, (err, salt) ->
    if err then callback winston.makeError err; return

    bcrypt.hash seedString, salt, (err, bcryptHash) ->
      hash = utils.getHash bcryptHash
      passwordResetCode = hash.substring 0, constants.PASSWORD_RESET_CODE_LENGTH
      callback null, passwordResetCode


exports.register = (firstName, lastName, email, password, callback) ->
  unless firstName then callback winston.makeMissingParamError 'firstName'; return
  unless lastName then callback winston.makeMissingParamError 'lastName'; return
  unless email then callback winston.makeMissingParamError 'email'; return
  unless password then callback winston.makeMissingParamError 'password'; return

  userUtils.hashPassword password, (error, passwordHash) ->
    if error then callback error; return

    userUtils.generatePasswordResetCode (error, passwordResetCode) ->
      if error then callback error; return

      user = new UserModel
        firstName: firstName
        lastName: lastName
        email: email
        passwordHash: passwordHash
        passwordResetCode: passwordResetCode

      user.save (mongoError, savedUser) ->
        if mongoError
          if mongoError.code is 11000
            callback()
          else
            callback winston.makeMongoError mongoError
        else
          callback null, savedUser

#callback without error, but also without user means that either the email or the password is wrong.
exports.login = (email, password, callback) ->
  unless email then callback winston.makeMissingParamError 'email'; return
  unless password then callback winston.makeMissingParamError 'password'; return

  UserModel.findOne { email: email }, (mongoError, user) ->
    if mongoError then callback winston.makeMongoError mongoError; return

    if not user then callback(); return

    userUtils.checkPassword password, user.passwordHash, (error, match) ->
      if error then callback error; return

      if not match
        winston.doWarn 'password does not match',
          email: email
        callback()
      else
        callback null, user

exports.getFullName = (user) ->
  unless user then return ''

  if user.firstName and user.lastName
    return user.firstName + ' ' + user.lastName
  else if user.firstName
    return user.firstName
  else if user.lastName
    return 'M. ' + user.lastName
  return ''


#Drop any fields we don't want to send to the client
exports.sanitizeUser = (user) ->
  unless user then return {}

  delete user.__v
  delete user._id
  delete user.passwordHash
  delete user.passwordResetCode
  delete user.personId
  delete user.timestamp

  user