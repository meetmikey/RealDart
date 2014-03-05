describe 'orEquals', () ->
  it 'array', () ->

    images = null
    images ||= []
    expect( images ).toEqual( [] )
    expect( images ).not.toEqual( null )

    images = ['a']
    images ||= []
    expect( images ).toEqual( ['a'] )
    expect( images ).not.toEqual( [] )

  it 'object', () ->

    images = null
    images ||= {}
    expect( images ).toEqual( {} )
    expect( images ).not.toEqual( null )

    images = {'foo': 'bar'}
    images ||= {}
    expect( images ).toEqual( {'foo': 'bar'} )
    expect( images ).not.toEqual( {} )

    images.unexpected ||= {}
    expect( images.unexpected ).toEqual( {} )