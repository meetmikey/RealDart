commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

userUtils = require commonAppDir + '/lib/userUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

routeUtils = require '../lib/routeUtils'

routeUser = this

exports.register = (req, res) ->
  unless req and req.body then routeUtils.sendFail res; return
  unless req.body.firstName then routeUtils.sendFail res, 'first name required'; return
  unless req.body.lastName then routeUtils.sendFail res, 'last name required'; return
  unless req.body.email then routeUtils.sendFail res, 'email required'; return
  unless req.body.password then routeUtils.sendFail res, 'password required'; return

  firstName = req.body.firstName
  lastName = req.body.lastName
  email = req.body.email
  password = req.body.password

  userUtils.register firstName, lastName, email, password, (error, user) ->
    if error then routeUtils.handleError res, error; return

    else unless user #if no user returned, it means that the user already existed.
      winston.doWarn 'Duplicate user registration',
        email: email
      routeUtils.sendFail res, 'Account already exists'
    else
      routeUtils.sendUserToken res, userUtils.sanitizeUser user

exports.login = (req, res) ->
  unless req and req.body then routeUtils.sendFail res; return
  unless req.body.email then routeUtils.sendFail res, 'email required'; return
  unless req.body.password then routeUtils.sendFail res, 'password required'; return

  email = req.body.email
  password = req.body.password

  userUtils.login email, password, (error, user) ->
    if error then routeUtils.handleError res, error; return

    else unless user #if no user returned, it means that either the email or password was wrong
      winston.doWarn 'failed login',
        email: email
      routeUtils.sendFail res, 'Incorrect email or password'
    else
      routeUtils.sendUserToken res, userUtils.sanitizeUser user

#Auth has already happened.  Just send the user.
exports.getUser = (req, res) ->
  unless req and req.user then res.send 400; return
  res.send
    user: userUtils.sanitizeUser req.user