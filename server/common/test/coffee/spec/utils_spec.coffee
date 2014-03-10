commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'
utils = require commonAppDir + '/lib/utils'

describe 'testSymmetricEncryption', () ->
  it 'generic case', () ->
    message = 'abcdefg'
    cipher = utils.encryptSymmetric message
    decipher = utils.decryptSymmetric cipher.encrypted, cipher.iv
    expect(message).toBe(decipher)