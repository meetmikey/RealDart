commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
googleHelpers = require commonAppDir + '/lib/googleHelpers'
fs = require 'fs'

jasmine.getEnv().defaultTimeoutInterval = 10000;

describe "getContactsJSONFromAPIData", ()->
  it "test generic case", () ->
    expectedJSON = [
        {"title":"Sahil Mehta","contactId":"2","groupIds" : ["6"],"firstName":"Sahil","lastName":"Mehta","emails":["svmehta@gmail.com","svm2004@columbia.edu","sahilspam@gmail.com"],"primaryEmail":"svmehta@gmail.com","phoneNumbers":[{"number":"516-301-7290","type":"mobile"}],"addressess":[{"formattedAddress":"41 E 8th Street \nChicago , Il 60605","city":"41 E 8th Street \nChicago , Il 60605","street":"41 E 8th Street","region":"Il","postcode":"60605"}],"birthday":"1984-02-03","websites":[{"href":"http://www.google.com/profiles/116117910582161066588","rel":"profile"}]},
        {"title":"svmknicks33@gmail.com","contactId":"3","firstName":"svmknicks33@gmail.com","emails":["svmknicks33@gmail.com"],"primaryEmail":"svmknicks33@gmail.com"},
        {"title":"Vivek Kuncham","contactId":"4","groupIds" : ["6"],"firstName":"Vivek","lastName":"Kuncham","emails":["vivek.kuncham@gmail.com"],"primaryEmail":"vivek.kuncham@gmail.com","phoneNumbers":[{"number":"516-286-8876","type":"mobile"}],"websites":[{"href":"http://www.google.com/profiles/100863583587918785217","rel":"profile"}]},
        {"title":"Brock, William (Exchange)","contactId":"5","firstName":"William","lastName":"Brock","emails":["wbrock@bear.com"],"primaryEmail":"wbrock@bear.com"},
        {"contactId":"a","emails":["college@fas.harvard.edu"],"primaryEmail":"college@fas.harvard.edu"},
        {"contactId":"d","emails":["Alomar1732@yahoo.com"],"primaryEmail":"Alomar1732@yahoo.com"},
        {"contactId":"e","emails":["idledesi@gmail.com"],"primaryEmail":"idledesi@gmail.com"},
        {"contactId":"f","emails":["vk201@optonline.net"],"primaryEmail":"vk201@optonline.net"},
        {"contactId":"10","emails":["admission@stanford.edu"],"primaryEmail":"admission@stanford.edu"},
        {"contactId":"11","emails":["heaphery@stanford.edu"],"primaryEmail":"heaphery@stanford.edu"}
    ]
    sampleJSON = JSON.parse(fs.readFileSync('../data/sampleGoogleContactsRes.json'))
    result = JSON.stringify(googleHelpers.getContactsJSONFromAPIData(sampleJSON?.feed?.entry))
    expectedResult = JSON.stringify(expectedJSON)
    expect(result).toBe(expectedResult)

describe "getGroupsJSONFromAPIData", ()->
  it "test generic case", () ->
    expectedJSON = [
        {"systemGroupId":"Contacts","title":"System Group: My Contacts","_id":"6"},
        {"systemGroupId":"Friends","title":"System Group: Friends","_id":"d"},
        {"systemGroupId":"Family","title":"System Group: Family","_id":"e"},
        {"systemGroupId":"Coworkers","title":"System Group: Coworkers","_id":"f"},
        {"title":"Starred in Android","_id":"6e2345640c805e2c"}
    ]
    sampleJSON = JSON.parse(fs.readFileSync('../data/sampleGoogleContactGroupsRes.json'))
    result = JSON.stringify(googleHelpers.getGroupsJSONFromAPIData(sampleJSON?.feed?.entry))
    expectedResult = JSON.stringify(expectedJSON)
    expect(result).toBe(expectedResult)

describe "getAddressForQuery", () ->
  address =
    formattedAddress : '41 E 8th Street \nChicago , Il 60605'
    city : 'Chicago'
    street : '41 E 8th Street'
    region : 'Il'
    postcode : '60605'

  it "full", () ->
    expect(googleHelpers.getAddressForQuery address).toBe(address.formattedAddress)

  it "zip", () ->
    subAddress=
      postcode : address.postcode

    expect(googleHelpers.getAddressForQuery subAddress).toBe(address.postcode)

  it "city", () ->
    subAddress=
      city : address.city

    expect(googleHelpers.getAddressForQuery subAddress).toBe(address.city)

  it "city+state", () ->
    subAddress=
      city : address.city
      region : address.region

    expect(googleHelpers.getAddressForQuery subAddress).toBe(address.city + ', ' + address.region)

  it "state", () ->
  it "city+state", () ->
    subAddress=
      region : address.region

    expect(googleHelpers.getAddressForQuery subAddress).toBe(address.region)

  it "not enough info", () ->
    subAddress=
      street : '41 E 8th St'

    expect(googleHelpers.getAddressForQuery subAddress).toBe(undefined)

describe "getLocationFromGoogleUserAddress", () ->
  it "test generic case", (done) ->
    address =
      formattedAddress : '41 E 8th Street \nChicago , Il 60605'
      city : 'Chicago'
      street : '41 E 8th Street'
      region : 'Il'
      postcode : '60605'

    expectedResult = {
      "lat":41.87170500000001,
      "lng":-87.62642199999999,
      "locationType":"ROOFTOP",
      "city":"Chicago",
      "streetAddress":"41 E 8th Street",
      "state":"Il",
      "zip":"60605",
      "source":"google_address"
    }

    googleHelpers.getLocationFromGoogleUserAddress address, (err, location) =>
      expect(JSON.stringify(location)).toBe(JSON.stringify(expectedResult))
      done()

###
describe "getLocationFromGoogleUserPhone", () ->
  it "test generic case", ()->
###