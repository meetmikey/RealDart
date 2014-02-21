commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

mailUtils = require commonAppDir + '/lib/mailUtils'

describe 'normalizeEmailAddress', () ->
  it 'fail case', () ->
    expect( mailUtils.normalizeEmailAddress(  ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( null ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( undefined ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( 1 ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( [] ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( {} ) ).toBe( '' )
    expect( mailUtils.normalizeEmailAddress( 'asdf' ) ).toBe( '' )

  it 'basic tests', () ->
    expect( mailUtils.normalizeEmailAddress( 'a@a.com' ) ).toBe( 'a@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'A@a.COM' ) ).toBe( 'a@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'abcd@a.com' ) ).toBe( 'abcd@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'a.b.c.d@a.com' ) ).toBe( 'abcd@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'a.b.c.d+asdf@a.com' ) ).toBe( 'abcd@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'a.B.C.d+aSDf@a.com' ) ).toBe( 'abcd@a.com' )
    expect( mailUtils.normalizeEmailAddress( 'a.B.C....d+a...SDf@a.com' ) ).toBe( 'abcd@a.com' )