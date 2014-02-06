homeDir = process.env['REAL_DART_HOME']

express = require('express')
conf = require ('./conf')
https = require ('https')
fs = require 'fs'
liConnect = require './lib/liConnect'
fbConnect = require './lib/fbConnect'
rdConnect = require './lib/rdConnect'
passport = require 'passport'
appInitUtils = require './lib/appInitUtils'
userUtils = require './lib/userUtils'
winston = require('./lib/winstonWrapper').winston

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
    app.use express.bodyParser()
    app.use express.cookieParser()
    app.use express.methodOverride()
    app.use express.static homeDir + '/../public'
    app.use express.compress()
    app.use express.cookieSession
      secret:conf.express.secret
    app.use passport.initialize()
    app.use passport.session()

  #app.post('register', passport.)

  app.get '/', (req, res) ->
    res.sendfile 'public/home.html'

  app.post '/register', userUtils.registerUserRequest
    

  #Local login
  app.post '/login', passport.authenticate 'local',
    successRedirect: '/'
    failureRedirect: '/login'

  #Facebook
  app.get '/auth/facebook', passport.authenticate 'facebook'
  app.get '/auth/facebook/callback'
    , passport.authenticate 'facebook',
        successRedirect: '/'
        failureRedirect: '/login'

  #LinkedIn
  app.get '/auth/linkedIn', passport.authenticate 'linkedin'
  app.get '/auth/linkedIn/callback'
    , passport.authenticate 'linkedin',
        successRedirect: '/'
        failureRedirect: '/login'

  app.listen conf.listenPort


#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'RealDart', initActions, postInit