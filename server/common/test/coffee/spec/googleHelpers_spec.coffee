commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
googleHelpers = require commonAppDir + '/lib/googleHelpers'
fs = require 'fs'
appInitUtils = require commonAppDir + '/lib/appInitUtils'
constants = require commonAppDir + '/constants'
mongooseConnect = require commonAppDir + '/lib/mongooseConnect'

mongooseConnect.initSync()

describe "cleanPhoneNumber", () ->
  it "test", () ->
    expectedResult = '5163122246'
    result = googleHelpers.cleanPhoneNumber('(516) 312-2246')
    expect(result).toBe(expectedResult)

describe "getContactsJSONFromAPIData", ()->
  it "test generic case", () ->
    expectedJSONItem = 
      "title":"Sahil Mehta"
      "googleContactId":"2"
      "groupIds":["6"]
      "firstName":"Sahil"
      "lastName":"Mehta"
      "emails":["svmehta@gmail.com","svm2004@columbia.edu","sahilspam@gmail.com"]
      "primaryEmail":"svmehta@gmail.com"
      "phoneNumbers":[{"number":"5163017290","type":"mobile"}]
      "addresses":[{"formattedAddress":"41 E 8th Street Chicago , Il 60605"
      "street":"41 E 8th Street","city":"Chicago","postcode":"60605"}]
      "birthday":"1984-02-03"
      "websites":[{"href":"http://www.google.com/profiles/116117910582161066588","rel":"profile"}]

    sampleJSON = JSON.parse(fs.readFileSync('../data/sampleGoogleContactsRes.json'))


    resultJSON = googleHelpers.getContactsJSONFromAPIData(sampleJSON?.feed?.entry)
    expect(resultJSON.length).toBe(10)

    #only compare the first item
    resultFirstItem = resultJSON[0]

    for key of resultFirstItem

      if typeof resultFirstItem[key] is 'object'
        test =  JSON.stringify(resultFirstItem[key])
        value = JSON.stringify(expectedJSONItem[key])
        expect(test).toBe(value)
      else
        expect(resultFirstItem[key]).toBe(expectedJSONItem[key])

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
      formattedAddress : '41 E 8th Street Chicago , Il 60605'
      city : 'Chicago'
      street : '41 E 8th Street'
      region : 'Il'
      postcode : '60605'

    expectedResult = {
      "lat":41.87170500000001,
      "lng":-87.62642199999999,
      "locationType":"ROOFTOP",
      "source":"google_address"
    }

    googleHelpers.getLocationFromGoogleUserAddress address, (err, location) =>
      expect(JSON.stringify(location)).toBe(JSON.stringify(expectedResult))
      done()

describe "getLocationFromGoogleUserPhone", () ->
  it "test success case", (done)->
  ##  appInitUtils.initApp 'googleHelpers_spec', initActions, () ->

    googleHelpers.getLocationFromGoogleUserPhone '5163122246', (err, data) ->
      expect(data.lng).toBe(-73.58318349999999)
      expect(data.lat).toBe(40.6576022)
      expect(data.state).toBe('NY')
      expect(data.city).toBe('Freeport')
      done()

  it "test bad phone number", (done)->
    googleHelpers.getLocationFromGoogleUserPhone '567897987987987987123', (err, data) ->
      expect(err).toBeTruthy()
      expect(err.log).toBe('area code could not be parsed from phone number')
      done()

  it "test invalid area code", (done)->
    googleHelpers.getLocationFromGoogleUserPhone '1234597893', (err, data) ->
      expect(data).toBe(undefined)
      done()

describe "addLocations", () ->
  it "test phone number", (done) ->
    contact =
      "isMyContact" : true,
      "googleUserId" : "101561212934818385722",
      "userId" : "53238c9f8656041907ae9fb6",
      "title" : "Paulius Virbickas",
      "contactId" : "738cda140e9c7b34",
      "groupIds" : "6",
      "firstName" : "Paulius",
      "lastName" : "Virbickas",
      "primaryEmail" : "paulius.v@gmail.com",
      "_id" : "53238dbdc6b79b4907bffae5",
      "addresses" : [ ],
      "websites" : [ ],
      "phoneNumbers" : [ {'number' : '5163122246', 'type': 'cell' }],
      "emails" : [ "paulius.v@gmail.com"]

    googleHelpers.addLocations contact, (err) ->
      expect(contact.phoneNumbers[0].location.length).toBe(1)
      done()
  
  it "test address", (done) ->
    contact =
      "isMyContact" : true,
      "googleUserId" : "101561212934818385722",
      "userId" : "53238c9f8656041907ae9fb6",
      "title" : "Paulius Virbickas",
      "contactId" : "738cda140e9c7b34",
      "groupIds" : "6",
      "firstName" : "Paulius",
      "lastName" : "Virbickas",
      "primaryEmail" : "paulius.v@gmail.com",
      "_id" : "53238dbdc6b79b4907bffae5",
      "addresses" : [{"formattedAddress":"41 E 8th Street \nChicago , Il 60605","city":"41 E 8th Street \nChicago , Il 60605","street":"41 E 8th Street","region":"Il","postcode":"60605"}],
      "websites" : [],
      "phoneNumbers" : [],
      "emails" : [ "paulius.v@gmail.com"]

    googleHelpers.addLocations contact, (err) ->
      expect(contact.addresses[0].location.length).toBe(1)
      done()
 
  it "test empty", (done) ->
    contact =
      "isMyContact" : true,
      "googleUserId" : "101561212934818385722",
      "userId" : "53238c9f8656041907ae9fb6",
      "title" : "Paulius Virbickas",
      "contactId" : "738cda140e9c7b34",
      "groupIds" : "6",
      "firstName" : "Paulius",
      "lastName" : "Virbickas",
      "primaryEmail" : "paulius.v@gmail.com",
      "_id" : "53238dbdc6b79b4907bffae5",
      "addresses" : [ ],
      "websites" : [ ],
      "phoneNumbers" : [ ],
      "emails" : [ "paulius.v@gmail.com"]

    googleHelpers.addLocations contact, (err) ->
      expect(contact.phoneNumbers.length).toBe(0)
      expect(contact.addresses.length).toBe(0)
      done()

  it "test multiple", (done) ->
    contact =
      "isMyContact" : true,
      "googleUserId" : "101561212934818385722",
      "userId" : "53238c9f8656041907ae9fb6",
      "title" : "Paulius Virbickas",
      "contactId" : "738cda140e9c7b34",
      "groupIds" : "6",
      "firstName" : "Paulius",
      "lastName" : "Virbickas",
      "primaryEmail" : "paulius.v@gmail.com",
      "_id" : "53238dbdc6b79b4907bffae5",
      "addresses" : [{"formattedAddress":"41 E 8th Street \nChicago , Il 60605","city":"41 E 8th Street \nChicago , Il 60605","street":"41 E 8th Street","region":"Il","postcode":"60605"}],
      "websites" : [ ],
      "phoneNumbers" : [ {'number' : '5163122246', 'type': 'cell' }, {'number' : '7187746060', 'type' : 'cell'}],
      "emails" : [ "paulius.v@gmail.com"]

    googleHelpers.addLocations contact, (err) ->
      expect(contact.phoneNumbers[0].location.length).toBe(1)
      expect(contact.phoneNumbers[1].location.length).toBe(1)
      expect(contact.addresses[0].location.length).toBe(1)
      done()


describe "cleanExtraSpacesAndNewLines", () ->
  it "test generic case", () ->
    expect(googleHelpers.cleanExtraSpacesAndNewLines(' this has too  many \n spaces and  new lines \n as well!!  ')).toBe('this has too many spaces and new lines as well!!')