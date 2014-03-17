commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

fs = require 'fs'
csv = require 'csv'
async = require 'async'
winston = require(commonAppDir + '/lib/winstonWrapper').winston
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
geocoding = require commonAppDir + '/lib/geocoding'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
AreaCodeModel = require(commonAppDir + '/schema/areaCode').AreaCodeModel
commonConstants = require commonAppDir + '/constants'
_ = require 'underscore'

initActions = [
  commonConstants.initAction.CONNECT_MONGO
]

inverseStateMap = commonConstants.US_STATE_CODES_INV

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
      
      async.eachSeries data, (item, eachCb) ->
        normalizeAreaCodeDatum(item)

        if item['State Code']

          newAreaCode = new AreaCodeModel
            _id : item['Area Code']
            state  : item['State Code']
            majorCities  : item['Cities']

          if newAreaCode.majorCities && newAreaCode.majorCities.length
            #TODO: get better geocode from whtiepages??
            address = newAreaCode.majorCities[0] + ', ' + newAreaCode.state
            geocoding.getGeocodeFromGoogle address, 'us', (err, geocode) ->
              return eachCb(err) if err

              newAreaCode.lat = geocode.lat
              newAreaCode.lng = geocode.lng

              newAreaCode.save (err) ->
                if err
                  eachCb(winston.makeMongoError err)
                else
                  eachCb()
        else
          winston.doInfo 'not processing', {item : item}
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