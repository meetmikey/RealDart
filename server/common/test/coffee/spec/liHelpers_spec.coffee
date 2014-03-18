commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
fs = require 'fs'
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'
liHelpers = require commonAppDir + '/lib/liHelpers'
mongooseConnect.initSync()

describe "getCurrentLocationFromLIUser", () ->
  it "test generic case", (done) ->
    liUserJson = JSON.parse(fs.readFileSync('../data/sampleLIUser.json'))
    expectedResult =
      'country' : 'us'
      'readableLocation' : 'San Francisco Bay Area'
      'source' : 'linkedin_location'
      "lat":37.7749295
      "lng":-122.4194155

    expectedResult = JSON.stringify(expectedResult)
    
    liHelpers.getCurrentLocationFromLIUser liUserJson, (err, data) ->
      location = JSON.stringify(data)
      expect(location).toBe(expectedResult)
      done()

describe "cleanLocationNameForGeocoding", () ->
  it "san francisco", () ->
    newLocation = liHelpers.cleanLocationNameForGeocoding('San Francisco Bay Area')
    expect(newLocation).toBe('San Francisco')

  it "greater", () ->
    newLocation = liHelpers.cleanLocationNameForGeocoding('Greater Hartford') 
    expect(newLocation).toBe('Hartford')

  it "greater ... area", () ->
    newLocation = liHelpers.cleanLocationNameForGeocoding('Greater Chicago Area')
    expect(newLocation).toBe('Chicago')

  it "only grab first + last occurrence", () ->
    newLocation = liHelpers.cleanLocationNameForGeocoding('Greater Greater Chicago Area Area')
    expect(newLocation).toBe('Greater Chicago Area')