commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

fs = require 'fs'
csv = require 'csv'
async = require 'async'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
ZipCodeModel = require(commonAppDir + '/schema/zipCode').ZipCodeModel
commonConstants = require commonAppDir + '/constants'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

postInit = () ->
  run (error) ->
    if error then winston.handleError error

    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

run = (callback) ->

  dataCSV = fs.readFileSync(process.env.REAL_DART_HOME + '/server/tools/data/us_postal_codes.csv')
  csv().from.string(dataCSV.toString('utf-8'), {columns : true})
    .to.array (data) ->
      async.each data, (item, eachCb) ->
        if item['State Abbreviation'] of commonConstants.US_STATE_CODES
          newZipCode = new ZipCodeModel
            _id : item['Postal Code']
            latitude : parseFloat(item['Latitude'])
            longitude : parseFloat(item['Longitude'])
            state  : item['State Abbreviation']
            county : item['County']
            city  : item['Place Name']

          newZipCode.save (err) ->
            if err
              eachCb(winston.makeMongoError err)
            else
              eachCb()
        else
          console.log 'not processing', item
          eachCb()
      , (err) ->
        if err
          winston.doError 'error saving zip codes', {err : err}
        else
          winston.doInfo 'done processing zips'
          callback()

#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'fillZipCodes', initActions, postInit