commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
googleHelpers = require commonAppDir + '/lib/googleHelpers'
fs = require 'fs'


describe "getContactsJSONFromAPIData", ()->
  it "test generic case", () ->
    expectedJSON = [{"title":"Sahil Mehta","firstName":"Sahil","lastName":"Mehta","emails":["svmehta@gmail.com","svm2004@columbia.edu","sahilspam@gmail.com"],"primaryEmail":"svmehta@gmail.com","phoneNumbers":[{"number":"516-301-7290","type":"mobile"}],"addressess":[{"formattedAddress":"41 E 8th Street \nChicago , Il 60605","city":"41 E 8th Street \nChicago , Il 60605","street":"41 E 8th Street","region":"Il","postcode":"60605"}],"birthday":"1984-02-03","websites":[{"href":"http://www.google.com/profiles/116117910582161066588","rel":"profile"}]},{"title":"svmknicks33@gmail.com","firstName":"svmknicks33@gmail.com","emails":["svmknicks33@gmail.com"],"primaryEmail":"svmknicks33@gmail.com"},{"title":"Vivek Kuncham","firstName":"Vivek","lastName":"Kuncham","emails":["vivek.kuncham@gmail.com"],"primaryEmail":"vivek.kuncham@gmail.com","phoneNumbers":[{"number":"516-286-8876","type":"mobile"}],"websites":[{"href":"http://www.google.com/profiles/100863583587918785217","rel":"profile"}]},{"title":"Brock, William (Exchange)","firstName":"William","lastName":"Brock","emails":["wbrock@bear.com"],"primaryEmail":"wbrock@bear.com"},{"emails":["college@fas.harvard.edu"],"primaryEmail":"college@fas.harvard.edu"},{"emails":["Alomar1732@yahoo.com"],"primaryEmail":"Alomar1732@yahoo.com"},{"emails":["idledesi@gmail.com"],"primaryEmail":"idledesi@gmail.com"},{"emails":["vk201@optonline.net"],"primaryEmail":"vk201@optonline.net"},{"emails":["admission@stanford.edu"],"primaryEmail":"admission@stanford.edu"},{"emails":["heaphery@stanford.edu"],"primaryEmail":"heaphery@stanford.edu"}]
    sampleJSON = JSON.parse(fs.readFileSync('../data/sampleGoogleContactsRes.json'))
    result = JSON.stringify(googleHelpers.getContactsJSONFromAPIData(sampleJSON?.feed?.entry))
    expectedResult = JSON.stringify(expectedJSON)
    expect(result).toBe(expectedResult)