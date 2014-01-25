homeDir = process.env['REAL_DART_HOME']
fbHelpers = require homeDir + '/lib/fbHelpers'

describe "getUpdateJSONForUser", ()->
  it "test generic case", () ->
    userData =
      'hello' : 'world'
      'more' : 'keys'
      '_id' : 'someId'

    updateJSON = JSON.stringify(fbHelpers.getUpdateJSONForUser userData)
    expectedUpdateJson = JSON.stringify({$set : {'hello' : 'world', 'more' : 'keys'}})

    expect(updateJSON).toBe(expectedUpdateJson)

describe "getFriendsFromFQLResponse", ()->
  it "test generic case", () ->
    fqlData = [ 
      name: 'friends', 
      fql_result_set: [ 
        { uid: 97, name: 'Evan Schwartz' },
        { uid: 359, name: 'Sarah Welch' },
        { uid: 791, name: 'Emily Zank' },
        { uid: 1283, name: 'Jacquie Rooney' },
        { uid: 1992, name: 'Andrew Chang' },
        { uid: 2118, name: 'Vijay Yanamadala' },
        { uid: 100001058538606, name: 'Naimish Dalal' },
        { uid: 100001098505068, name: 'Max Rodes' },
        { uid: 100001148208542, name: 'Manish Dalal' },
        { uid: 100001148234495, name: 'Mike Muryn' },
        { uid: 100001316756017, name: 'Sharon Kao' },
        { uid: 100001408517657, name: 'Sandhya Shah' },
        { uid: 100001696373537, name: 'Louis Li' },
        { uid: 100001711938243, name: 'Ila Shah' },
        { uid: 100001722581267, name: 'Vaishali Chokshi' },
        { uid: 100001974663062, name: 'Atsushi Mizushima' },
        { uid: 100002084388107, name: 'Benoit Passot' },
        { uid: 100002592562485, name: 'Miraj Mohsin' },
        { uid: 100002912783751, name: 'Teddy Cross' },
        { uid: 100003111527071, name: 'Charmi Shah' },
        { uid: 100003166148831, name: 'Sudha Shah' },
        { uid: 100003471485062, name: 'Diya Dalal' },
        { uid: 100006600911049, name: 'Rick Barber' },
        { uid: 100007208463126, name: 'Yash Dalal' } ]
    ]

    result = JSON.stringify(fbHelpers.getFriendsFromFQLResponse(fqlData))
    expectedResult = JSON.stringify(fqlData[0].fql_result_set)
    expect(result).toBe(expectedResult)