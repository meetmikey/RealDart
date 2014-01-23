fbConnect = require '../../../app/lib/fbConnect'

describe "getUpdateJSON", ()->
  it "test getUpdateJSON", () ->
    userData =
      'hello' : 'world'
      'more' : 'keys'
      '_id' : 'someId'

    updateJSON = JSON.stringify(fbConnect.getUpdateJSON userData)
    expectedUpdateJson = JSON.stringify({$set : {'hello' : 'world', 'more' : 'keys'}})

    expect(updateJSON).toBe(expectedUpdateJson)