commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
publicDir = __dirname + '/public'

express = require 'express'
jwt = require 'jsonwebtoken'
expressJwt = require 'express-jwt'
https = require 'https'
fs = require 'fs'
passport = require 'passport'
ejs = require 'ejs'

appInitUtils = require commonAppDir + '/lib/appInitUtils'
userUtils = require commonAppDir + '/lib/userUtils'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

commonConstants = require commonAppDir + '/constants'
commonConf = require commonAppDir + '/conf'

liConnect = require './lib/liConnect'
fbConnect = require './lib/fbConnect'
googleConnect = require './lib/googleConnect'
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

  app.get '/preAuth/:service', (req, res) ->
    service = req?.params?.service
    res.render 'preAuth.html',
      service: service

  #Authentication
  app.post '/login', routeUser.login
  app.post '/register', routeUser.register


  #API
  # Note: All authenticated routes should be '/api/...' to use express-jwt authentication
  app.get '/api/user', routeUser.getUser

  addAuth app, commonConstants.service.GOOGLE
  addAuth app, commonConstants.service.LINKED_IN
  addAuth app, commonConstants.service.FACEBOOK

  #Start 'er up
  app.listen conf.server.listenPort


addAuth = (app, service) ->
  passportName = service.toLowerCase()

  app.post '/auth/' + service, (req, res, next) ->
    token = req?.body?.token

    jwt.verify token, routeUtils.getJWTSecret(), (err, user) ->
      if err
        winston.doError 'invalid token',
          err: err
          token: token
          secret: routeUtils.getJWTSecret()
        res.redirect '/#login'
        return

      options =
        state: JSON.stringify
          userId: user._id

      if service is commonConstants.service.GOOGLE
        options.accessType = commonConf.auth.google.accessType
        options.scope = commonConf.auth.google.scope

      passport.authenticate( passportName, options )(req, res, next)

  app.get '/auth/' + service + '/callback'
    , passport.authenticate( passportName, {session: false, failureRedirect: '/auth/' + service + '/callbackFail'} )
    , (req, res) ->
        routeUtils.sendCallbackHTML res, service, true

  app.get '/auth/' + service + '/callbackFail'
    , (req, res) ->
        routeUtils.sendCallbackHTML res, service, false


#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'RealDart', initActions, postInit
