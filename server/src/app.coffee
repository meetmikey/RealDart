homeDir = process.env['REAL_DART_HOME']

express = require 'express'
expressJwt = require 'express-jwt'
https = require 'https'
fs = require 'fs'
passport = require 'passport'

liConnect = require './lib/liConnect'
fbConnect = require './lib/fbConnect'
appInitUtils = require './lib/appInitUtils'
routeUtils = require './lib/routeUtils'
userUtils = require './lib/userUtils'
winston = require('./lib/winstonWrapper').winston
conf = require './conf'

routeUser = require './route/user'

initActions = [
  appInitUtils.CONNECT_MONGO
]

postInit = () =>

  app = module.exports = express()

  app.configure () ->
    app.engine 'html', require('ejs').__express
    app.use express.logger
      format: '\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :date \x1b[0m :response-time ms'
    app.use express.errorHandler
      dumpExceptions: true
      showStack: true
    app.use express.urlencoded()
    app.use express.json()
    app.use express.cookieParser()
    app.use express.methodOverride()
    app.use express.static homeDir + '/../public'
    app.use express.compress()

    #TODO: use a private key file. See...
    #https://github.com/auth0/node-jsonwebtoken
    app.use '/api', expressJwt
      secret: routeUtils.getJWTSecret()

    #not sure about these with new token stuff...need to come back here.
    #app.use passport.initialize()
    #app.use passport.session()

  app.get '/', (req, res) ->
    res.sendfile 'public/home.html'

  app.post '/login', routeUser.login
  app.post '/register', routeUser.register

  app.get '/api/user', routeUser.getUser

  #Facebook
  app.get '/auth/facebook', passport.authenticate 'facebook'
  app.get '/auth/facebook/callback', passport.authenticate 'facebook',
    successRedirect: '/'
    failureRedirect: '/login'

  #LinkedIn
  app.get '/auth/linkedIn', passport.authenticate 'linkedin'
  app.get '/auth/linkedIn/callback', passport.authenticate 'linkedin',
    successRedirect: '/'
    failureRedirect: '/login'

  app.listen conf.listenPort


#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'RealDart', initActions, postInit