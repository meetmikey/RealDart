commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

ContactModel = require(commonAppDir + '/schema/contact').ContactModel
winston = require(commonAppDir + '/lib/winstonWrapper').winston
utils = require commonAppDir + '/lib/utils'
appInitUtils = require commonAppDir + '/lib/appInitUtils'

constants = require commonAppDir + '/constants'

initActions = [
  constants.initAction.CONNECT_MONGO
]

run = (callback) ->

  c1 = new ContactModel
    emails: ['a@a.a']

  winston.doInfo 'c1',
    c1: c1

  utils.removeEmptyFields c1, true, true

  winston.doInfo 'c1 no nulls',
    c1: c1

  c2 = new ContactModel
    emails: [undefined]

  winston.doInfo 'c2',
    c2: c2

  utils.removeEmptyFields c2, true, true

  winston.doInfo 'c2 no nulls',
    c2: c2

  c2.save (error) ->
    if error then callback winston.makeMongoError error; return

    callback()


appInitUtils.initApp 'mongooseSave', initActions, run