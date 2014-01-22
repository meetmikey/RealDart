describe 'undefined', () ->

  testFunc = (input) ->
    expect( input ).toBe( undefined )

  it 'void 0', ->
    testFunc()