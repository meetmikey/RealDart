winston = require('./winstonWrapper').winston
webUtils = require './webUtils'
utils = require './utils'
s3Utils = require './s3Utils'

constants = require '../constants'
conf = require '../conf'

imageUtils = this


exports.importContactImage = (imageSourceURL, contact, callback) ->
  unless imageSourceURL then callback winston.makeMissingParamError 'imageSourceURL'; return
  unless contact then callback winston.makeMissingParamError 'contact'; return

  utils.runWithRetries webUtils.webGet, constants.DEFAULT_WEB_GET_ATTEMPTS
  , (error, response, resolvedURL, responseHeaders) ->
    if error then callback error; return
    unless response then callback winston.makeError 'no response'; return

    s3Filename = imageUtils.getS3FilenameForNewContactImage()
    s3Path = imageUtils.getContactImageS3Path s3Filename
    s3FileHeaders = {}
    if responseHeaders?['content-type'] then s3FileHeaders['content-type'] = responseHeaders['content-type']
    if responseHeaders?['content-length'] then s3FileHeaders['content-length'] = responseHeaders['content-length']

    s3Utils.putStream response, s3Path, s3FileHeaders, (error) ->
      if error then callback error; return

      contact.images ||= []
      for image in contact.images
        if image.sourceURL is imageSourceURL
          image.s3Filename = s3Filename

      contact.save (mongoError) ->
        if mongoError then callback winston.makeMongoError mongoError; return

        callback null, s3Filename

  , imageSourceURL, false


exports.getS3FilenameForNewContactImage = () ->
  # kind of dumb, but use randomString to avoid collisions
  uniqueId = utils.getUniqueId()
  s3Filename = 'img_' + uniqueId
  s3Filename


exports.getContactImageS3Path = (s3Filename) ->
  unless s3Filename then winston.doMissingParamError 's3Filename'; return ''

  s3Path = conf.aws.s3.folder.contactImage + '/' + s3Filename
  s3Path


exports.deleteContactImage = (s3Filename, callback) ->
  unless s3Filename then callback winston.makeMissingParamError 's3Filename'; return

  s3Path = imageUtils.getContactImageS3Path s3Filename
  s3Utils.deleteFile s3Path, callback