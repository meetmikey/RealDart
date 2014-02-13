commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

jwt = require 'jsonwebtoken'

winston = require(commonAppDir + '/lib/winstonWrapper').winston

conf = require '../conf'

routeUtils = this

exports.getJWTSecret = () ->
  #TODO: use a private key file. See...
  #https://github.com/auth0/node-jsonwebtoken
  conf.session.jwtSecret

exports.sendOK = (res, data) ->
  data = data || {ok: true}
  res.send 200, JSON.stringify data

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

exports.sendCallbackHTML = (res, service, isSuccess) ->
  status = 'fail'
  if isSuccess
    status = 'success'
  targetOrigin = routeUtils.getProtocolHostAndPort()

  res.render 'callback.html',
    message: JSON.stringify
      service: service
      status: status
    targetOrigin: targetOrigin


exports.getProtocolHostAndPort = () ->
  result = 'http'
  if conf.server.useSSL
    result += 's'
  result += '://'
  result += conf.server.host
  if conf.server.listenPort
    result += ':' + conf.server.listenPort
  result

exports.getUserIdFromAuthRequest  = (req) ->
  dataVar = 'state'
  dataString = req?.query?[dataVar]
  data = null
  try
    data = JSON.parse dataString
  catch exception
    winston.doError 'data string parse exception',
      exception: exception
      datatString: dataString

  userId = data?.userId
  userId