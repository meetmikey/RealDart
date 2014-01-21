express = require('express')
conf = require ('./conf')
https = require ('https')
fs = require ('fs')
fb_connect = require('./lib/fb_connect')
passport = require('passport')

app = module.exports = express()

app.configure ()->
  app.engine('html', require('ejs').__express)
  app.use(express.logger({ format:'\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :date \x1b[0m :response-time ms' }))
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
  app.use(express.bodyParser())
  app.use(express.cookieParser())
  app.use(express.methodOverride())
  app.use(express.static(__dirname + '/public'))
  app.use(express.compress())
  app.use(express.cookieSession({secret:conf.express.secret}))

app.get('/auth/facebook', passport.authenticate('facebook'))

app.get('/auth/facebook/callback', 
  passport.authenticate('facebook', { successRedirect: '/', failureRedirect: '/login' }))

app.listen (3000)