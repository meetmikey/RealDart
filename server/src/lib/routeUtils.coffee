jwt = require 'jsonwebtoken'

winston = require('./winstonWrapper').winston

conf = require '../conf'

routeUtils = this

exports.getJWTSecret = () ->
  #TODO: use a private key file. See...
  #https://github.com/auth0/node-jsonwebtoken
  conf.session.jwtSecret

#Not a server error, but some failure.  Probably authentication failure.
exports.sendFail = (res, error) ->
  error = error || ''
  response = JSON.stringify {error: error}
  res.send 400, response
  winston.doWarn 'api call failed',
    error: error

#Handle a server error.
exports.handleError = (res, error) ->
  res.send 500, 'internal error'
  unless error
    error = winston.makeError 'unspecified server error!'
  winston.handleError error

exports.sendUserToken = (res, user) ->
  secret = routeUtils.getJWTSecret()
  token = jwt.sign user, secret,
    expiresInMinutes: conf.session.expireTimeMinutes
  res.json
    token: token