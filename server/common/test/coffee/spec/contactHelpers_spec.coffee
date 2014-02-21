commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

contactHelpers = require commonAppDir + '/lib/contactHelpers'
winston = require(commonAppDir + '/lib/winstonWrapper').winston

describe 'parseFullName', () ->

  it 'fail', () ->
    test null, null, null, null
    test [], null, null, null
    test {}, null, null, null
    test 0, null, null, null

  it 'first last', () ->
    test 'Leeroy Jenkins', 'Leeroy', null, 'Jenkins'
    test '  Leeroy   Jenkins  ', 'Leeroy', null, 'Jenkins'

  it 'first middle last', () ->
    test 'Leeroy Gunsupletsdothis Jenkins', 'Leeroy', 'Gunsupletsdothis', 'Jenkins'

  it 'first middle1 middle2 last', () ->
    test 'Leeroy Gunsup Letsdothis Jenkins', 'Leeroy', 'Gunsup Letsdothis', 'Jenkins'    

  it 'prefix first last', () ->
    test 'M. Leeroy Jenkins', 'Leeroy', null, 'Jenkins'
    test 'M Leeroy Jenkins', 'Leeroy', null, 'Jenkins'
    test 'Dr Leeroy Jenkins', 'Leeroy', null, 'Jenkins'
    test 'DR Leeroy Jenkins', 'Leeroy', null, 'Jenkins'

  it 'last, first', () ->
    test 'Jenkins, Leeroy', 'Leeroy', null, 'Jenkins'
    test ' Jenkins ,  Leeroy ', 'Leeroy', null, 'Jenkins'

  it 'last, first middle(s)', () ->
    test 'Jenkins, Leeroy Gunsupletsdothis', 'Leeroy', 'Gunsupletsdothis', 'Jenkins'
    test 'Jenkins, Leeroy Gunsup Letsdothis', 'Leeroy', 'Gunsup Letsdothis', 'Jenkins'

  it 'first last suffix(s)', () ->
    test 'Leeroy Jenkins Esq', 'Leeroy', null, 'Jenkins'
    test 'Leeroy Jenkins Esq.', 'Leeroy', null, 'Jenkins'
    test 'Leeroy Jenkins, Esq.', 'Leeroy', null, 'Jenkins'
    test 'Leeroy Jenkins, Esq., PHD', 'Leeroy', null, 'Jenkins'

  it 'first (middle) el last', () ->
    test 'Leeroy El Jenkins', 'Leeroy', null, 'El Jenkins'
    test 'Leeroy Gunsupletsdothis El Jenkins', 'Leeroy', 'Gunsupletsdothis', 'El Jenkins'


test = (fullName, firstName, middleName, lastName) ->
  parsedFullName = contactHelpers.parseFullName fullName
  expect( parsedFullName.firstName ).toBe( firstName )
  expect( parsedFullName.middleName ).toBe( middleName )
  expect( parsedFullName.lastName ).toBe( lastName )