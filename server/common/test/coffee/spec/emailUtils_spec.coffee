commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

emailUtils = require commonAppDir + '/lib/emailUtils'


describe 'normalizeEmailAddress', () ->
  it 'fail case', () ->
    expect( emailUtils.normalizeEmailAddress(  ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( null ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( undefined ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( 1 ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( [] ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( {} ) ).toBe( '' )
    expect( emailUtils.normalizeEmailAddress( 'asdf' ) ).toBe( '' )

  it 'basic tests', () ->
    expect( emailUtils.normalizeEmailAddress( 'a@a.com' ) ).toBe( 'a@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'A@a.COM' ) ).toBe( 'a@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'abcd@a.com' ) ).toBe( 'abcd@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'a.b.c.d@a.com' ) ).toBe( 'abcd@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'a.b.c.d+asdf@a.com' ) ).toBe( 'abcd@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'a.B.C.d+aSDf@a.com' ) ).toBe( 'abcd@a.com' )
    expect( emailUtils.normalizeEmailAddress( 'a.B.C....d+a...SDf@a.com' ) ).toBe( 'abcd@a.com' )

describe 'getCleanSubject', () ->
  it 'fail', () ->
    expect( emailUtils.getCleanSubject(  ) ).toBe( '' )
    expect( emailUtils.getCleanSubject( null ) ).toBe( '' )
    expect( emailUtils.getCleanSubject( undefined ) ).toBe( '' )
    expect( emailUtils.getCleanSubject( [] ) ).toBe( '' )
    expect( emailUtils.getCleanSubject( {} ) ).toBe( '' )
    expect( emailUtils.getCleanSubject( 12 ) ).toBe( '' )

  it 'none', () ->
    expect( emailUtils.getCleanSubject( 'asdf' ) ).toBe( 'asdf' )
    expect( emailUtils.getCleanSubject( 'ASDF 1234' ) ).toBe( 'ASDF 1234' )

  it 'single', () ->
    expect( emailUtils.getCleanSubject( 'Re: aB' ) ).toBe( 'aB' )
    expect( emailUtils.getCleanSubject( 're: aB' ) ).toBe( 'aB' )
    expect( emailUtils.getCleanSubject( 'fwd: aB' ) ).toBe( 'aB' )
    expect( emailUtils.getCleanSubject( '   aB' ) ).toBe( 'aB' )

  it 'multiple', () ->
    expect( emailUtils.getCleanSubject( 'Re:FWD: aB' ) ).toBe( 'aB' )
    expect( emailUtils.getCleanSubject( 're: fwd: FWD: aB' ) ).toBe( 'aB' )


describe 'isValidEmail', () ->
  it 'fail case', () ->
    expect( emailUtils.isValidEmail() ).toBe( false )
    expect( emailUtils.isValidEmail( null ) ).toBe( false )
    expect( emailUtils.isValidEmail( undefined ) ).toBe( false )
    expect( emailUtils.isValidEmail( [] ) ).toBe( false )
    expect( emailUtils.isValidEmail( ['a'] ) ).toBe( false )
    expect( emailUtils.isValidEmail( {} ) ).toBe( false )
    expect( emailUtils.isValidEmail( {'foo': 'bar'} ) ).toBe( false )
    expect( emailUtils.isValidEmail( 123 ) ).toBe( false )