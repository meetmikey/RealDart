commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
workerAppDir = commonAppDir + '/../../worker/app'

constants = commonAppDir + '/constants'

mailDownloadHelpers = require workerAppDir + '/lib/mailDownloadHelpers'

describe 'uidBatching', ()->
  it 'fail case', () ->
    test null, null, 2, []

  it '0 min', () ->

    test 0, 0, 2, [ [ 0, 0 ] ]
    test 0, 3, 2, [ [ 0, 1 ], [ 2, 3 ] ]
    test 0, 4, 2, [ [ 0, 1 ], [ 2, 3 ], [ 4, 4 ] ]

  it '1 min', () ->
    test 1, 1, 2, [ [ 1, 1 ] ]
    test 1, 2, 2, [ [ 1, 2 ] ]
    test 1, 4, 2, [ [ 1, 2 ], [ 3, 4 ] ]
    test 1, 5, 2, [ [ 1, 2 ], [ 3, 4 ], [ 5, 5 ] ]

  it 'size 3', () ->
    test 0, 4, 3, [ [ 0, 2 ], [ 3, 4 ] ]    
    

test = (minUID, maxUID, batchSize, batchesInfo ) ->
  testValue = mailDownloadHelpers.getUIDBatches minUID, maxUID, batchSize
  testValueString = JSON.stringify testValue

  expectedValue = []
  for batchInfo in batchesInfo
    batch =
      minUID: batchInfo[0]
      maxUID: batchInfo[1]
    expectedValue.push batch

  expectedValueString = JSON.stringify expectedValue

  expect( testValueString ).toBe( expectedValueString )

###
testBatching 0, 0
testBatching 0, 3
testBatching 0, 4
testBatching 1, 1
testBatching 1, 2
testBatching 1, 4
testBatching 1, 5
###