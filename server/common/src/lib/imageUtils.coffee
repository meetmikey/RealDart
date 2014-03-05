winston = require('./winstonWrapper').winston
webUtils = require './webUtils'
utils = require './utils'
s3Utils = require './s3Utils'

constants = require '../constants'
conf = require '../conf'

imageUtils = this


exports.importContactImage = (imageURL, contact, callback) ->
  unless imageURL then callback winston.makeMissingParamError 'imageURL'; return
  unless contact then callback winston.makeMissingParamError 'contact'; return

  utils.runWithRetries webUtils.webGet, constants.DEFAULT_WEB_GET_ATTEMPTS
  , (error, response, url, responseHeaders) ->
    if error then callback error; return
    unless response then callback winston.makeError 'no response'; return

    s3Filename = imageUtils.getS3FilenameForNewContactImage contact
    s3Path = imageUtils.getContactImageS3Path s3Filename

    s3Utils.putStream response, s3Path, responseHeaders, false, (error) ->
      if error then callback error; return

      contact.images ||= []
      contact.images.push s3Filename

      contact.save (mongoError) ->
        if mongoError then callback winston.makeMongoError mongoError; return

        callback null, s3Filename

  , imageURL, false


exports.getS3FilenameForNewContactImage = (contact) ->
  unless contact then winston.doMissingParamError 'contact'; return ''

  imageIndex = 0
  if contact.images and contact.images.length
    imageIndex = contact.images.length

  # kind of dumb, but use randomString to avoid race conditions
  randomString = utils.getRandomId 5

  s3Filename = 'img_' + contact._id + '_' + imageIndex.toString() + '_' + randomString
  s3Filename


exports.getContactImageS3Path = (s3Filename) ->
  unless s3Filename then winston.doMissingParamError 's3Filename'; return ''

  s3Path = conf.aws.s3.folder.contactImage + '/' + s3Filename
  s3Path


exports.deleteContactImage = (s3Filename, callback) ->
  unless s3Filename then callback winston.makeMissingParamError 's3Filename'; return

  s3Path = imageUtils.getContactImageS3Path s3Filename
  s3Utils.deleteFile s3Path, callback