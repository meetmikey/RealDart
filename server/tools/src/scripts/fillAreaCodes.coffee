commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

fs = require 'fs'
csv = require 'csv'
async = require 'async'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
AreaCodeModel = require(commonAppDir + '/schema/areaCode').AreaCodeModel
commonConstants = require commonAppDir + '/constants'
_ = require 'underscore'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

inverseStateMap = {}

for key of commonConstants.US_STATE_CODES
  inverseStateMap[commonConstants.US_STATE_CODES[key]] = key

postInit = () ->
  run (error) ->
    if error then winston.handleError error

    mongooseConnect.disconnect()
    winston.doInfo 'Done.'

normalizeAreaCodeDatum = (datum) ->
  for k of datum
    if k != ''
      datum[k] = datum[k].trim()
    else
      delete datum[k]

  datum['Area Code'] = datum['Area Code'].split(" ")[0]
  datum['State Code'] = inverseStateMap[datum['State/Province']]
  datum['Cities'] = _.map(datum['Major Cities By Population'].split(","), (city) -> city.trim())

run = (callback) ->

  dataCSV = fs.readFileSync(process.env.REAL_DART_HOME + '/server/tools/data/area_codes.csv')
  csv().from.string(dataCSV.toString('utf-8'), {columns : true})
    .to.array (data) ->
      
      async.each data, (item, eachCb) ->
        normalizeAreaCodeDatum(item)

        if item['State Code']

          newAreaCode = new AreaCodeModel
            _id : item['Area Code']
            state  : item['State Code']
            majorCities  : item['Cities']

          newAreaCode.save (err) ->
            if err
              eachCb(winston.makeMongoError err)
            else
              eachCb()
        else
          console.log 'not processing', item
          eachCb()
 
      , (err) ->
        if err
          winston.doError 'error saving area code', {err : err}
        else
          winston.doInfo 'done processing area codes'
          callback()

#initApp() will not callback an error.
#If something fails, it will just exit the process.
appInitUtils.initApp 'fillAreaCodes', initActions, postInit