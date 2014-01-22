async = require 'async'
mongoose_connect = require './mongoose_connect'
utils = require './utils'

environment = process.env.NODE_ENV
app_init_utils = this

exports.CONNECT_MONGO = 'mongoConnect'

exports.initApp = ( appName, actions, callback ) =>

  console.log appName + ' app starting...'

  if not utils.isArray actions
    console.log appName + ' app init successful, no required actions.'
    callback()

  else
    async.each actions, app_init_utils.doInitAction, ( err ) =>
      if err
        console.error appName + ' app init failed!', {err: err}
        process.exit 1

      else
        console.log appName + ' app init successful'
        callback()


exports.doInitAction = ( action, callback ) =>

  if not action
    callback 'no param: action'
    return

  switch action

    when app_init_utils.CONNECT_MONGO
      mongoose_connect.init callback
      break
    
    else
      callback 'invalid init action: ' + action