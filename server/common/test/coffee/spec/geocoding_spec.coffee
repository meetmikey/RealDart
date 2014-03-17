commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

geocoding = require commonAppDir + '/lib/geocoding'

describe "getAreaCodeFromPhoneNumber", ()->
  it 'starts with 1', () ->
    expect(geocoding.getAreaCodeFromPhoneNumber('15163122246')).toBe('516')
  it '9 digits', () ->
    expect(geocoding.getAreaCodeFromPhoneNumber('5163122246')).toBe('516')
  it 'no area code', () ->
    expect(geocoding.getAreaCodeFromPhoneNumber('3122246')).toBe(undefined)
  it 'unrecognized', () ->
    expect(geocoding.getAreaCodeFromPhoneNumber('5163122246789')).toBe(undefined)