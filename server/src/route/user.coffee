userUtils = require '../lib/userUtils'
winston = require('../lib/winstonWrapper').winston

routeUser = this

exports.register = (req, res) ->
  unless req and req.body then res.send 400; return
  unless req.body.firstName then res.send 400, 'first name required'; return
  unless req.body.lastName then res.send 400, 'last name required'; return
  unless req.body.email then res.send 400, 'email required'; return
  unless req.body.password then res.send 400, 'password required'; return

  firstName = req.body.firstName
  lastName = req.body.lastName
  email = req.body.email
  password = req.body.password

  userUtils.registerUser firstName, lastName, email, password, (error, user) ->
    if error
      winston.handleError error
      res.send 500
    else unless user #if no user returned, it means that the user already existed.
      winston.doWarn 'duplicate user registration',
        email: email
      res.send 400, 'account already exists'
    else
      res.send 200