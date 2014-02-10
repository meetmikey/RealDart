commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

winston = require(commonAppDir + '/lib/winstonWrapper').winston
GoogleUserModel = require(commonAppDir + '/schema/googleUser').GoogleUserModel
commonConf = require commonAppDir + '/conf'

googleHelpers = this

exports.getUserJSONFromProfile = (profile) ->
  userJSON = {}
  omitKeys = [
  ]
  for key, value of profile
    if omitKeys.indexOf( key ) isnt -1
      continue
    else if key is 'emails'
      emails = []
      for emailObject in value
        email = emailObject['value']
        emails.push email
      userJSON[key] = emails
    else
      userJSON[key] = value
  userJSON