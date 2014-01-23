fbConnect = require '../../../app/lib/fbConnect'

describe "getUpdateJSONForUser", ()->
  it "test getUpdateJSONForUser", () ->
    userData =
      'hello' : 'world'
      'more' : 'keys'
      '_id' : 'someId'

    updateJSON = JSON.stringify(fbConnect.getUpdateJSONForUser userData)
    expectedUpdateJson = JSON.stringify({$set : {'hello' : 'world', 'more' : 'keys'}})

    expect(updateJSON).toBe(expectedUpdateJson)