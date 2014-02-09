commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
publicDir = __dirname + '/public'

console.log '__dirname: ' + __dirname
console.log 'publicDir: ' + publicDir

express = require 'express'
expressJwt = require 'express-jwt'
https = require 'https'
fs = require 'fs'
passport = require 'passport'
ejs = require 'ejs'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
userUtils = require commonAppDir + '/lib/userUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

commonConstants = require commonAppDir + '/constants'

liConnect = require './lib/liConnect'
fbConnect = require './lib/fbConnect'
routeUtils = require './lib/routeUtils'
routeUser = require './route/user'
conf = require './conf'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

postInit = () =>

  app = module.exports = express()

  app.configure () ->
    app.engine 'html', ejs.__express
    app.use express.logger
      format: '\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :date \x1b[0m :response-time ms'
    app.use express.errorHandler
      dumpExceptions: true
      showStack: true
    app.use express.urlencoded()
    app.use express.json()
    app.use express.cookieParser()
    app.use express.methodOverride()
    app.use express.cookieSession
      secret:conf.express.secret
    app.use express.static publicDir
    app.use express.compress()
    app.set 'views', publicDir + '/html'
    app.use passport.initialize()
    app.use passport.session()
    app.use '/api', expressJwt
      secret: routeUtils.getJWTSecret()



  #The home page (with the full backbone app)
  app.get '/', (req, res) ->
    res.sendfile publicDir + '/html/home.html'

  #Authentication
  app.post '/login', routeUser.login
  app.post '/register', routeUser.register


  #API
  # Note: All authenticated routes should be '/api/...' to use express-jwt authentication
  app.get '/api/user', routeUser.getUser



  #Facebook
  app.get '/auth/facebook', passport.authenticate 'facebook'
  app.get '/auth/facebook/callback'
    , passport.authenticate( 'facebook', {session: false, failureRedirect: '/auth/facebook/callbackFail'} )
    , (req, res) ->
        routeUtils.sendCallbackHTML res, 'facebook', true
  app.get '/auth/facebook/callbackFail'
    , (req, res) ->
        routeUtils.sendCallbackHTML res, 'facebook', false


  #LinkedIn
  app.get '/auth/linkedIn', passport.authenticate 'linkedin'
  app.get '/auth/linkedIn/callback'
    , passport.authenticate( 'linkedin', {session: false, failureRedirect: '/auth/linkedIn/callbackFail'} )
    , (req, res) ->
        routeUtils.sendCallbackHTML res, 'linkedIn', true
  app.get '/auth/linkedIn/callbackFail'
    , (req, res) ->
        routeUtils.sendCallbackHTML res, 'linkedIn', false


  #Start 'er up
  app.listen conf.server.listenPort


#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'RealDart', initActions, postInit