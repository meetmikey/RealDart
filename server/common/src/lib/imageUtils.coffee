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
  , (error, response, url, responseHeaders) ->
    if error then callback error; return
    unless response then callback winston.makeError 'no response'; return

    s3Filename = imageUtils.getS3FilenameForNewContactImage contact
    s3Path = imageUtils.getContactImageS3Path s3Filename
    s3FileHeaders = {}
    if responseHeaders?['content-type'] then s3FileHeaders['content-type'] = responseHeaders['content-type']
    if responseHeaders?['content-length'] then s3FileHeaders['content-length'] = responseHeaders['content-length']

    s3Utils.putStream response, s3Path, s3FileHeaders, false, (error) ->
      if error then callback error; return

      contact.imageS3Filenames ||= []
      contact.imageS3Filenames.push s3Filename

      # Remove this image from the array of images to be imported
      # And filter out any bad imageSourceURLs while we're at it.  I was seeing some null ones creep in.
      tempImageSourceURLs = []

      contact.imageSourceURLs ||= []
      for tempImageSourceURL in contact.imageSourceURLs
        if tempImageSourceURL and tempImageSourceURL isnt imageSourceURL
          tempImageSourceURLs.push tempImageSourceURL
      contact.imageSourceURLs = tempImageSourceURLs

      contact.save (mongoError) ->
        if mongoError then callback winston.makeMongoError mongoError; return

        callback null, s3Filename

  , imageSourceURL, false


exports.getS3FilenameForNewContactImage = (contact) ->
  unless contact then winston.doMissingParamError 'contact'; return ''

  # kind of dumb, but use randomString to avoid race conditions
  randomString = utils.getRandomId 8

  s3Filename = 'img_' + contact._id + '_' + randomString
  s3Filename


exports.getContactImageS3Path = (s3Filename) ->
  unless s3Filename then winston.doMissingParamError 's3Filename'; return ''

  s3Path = conf.aws.s3.folder.contactImage + '/' + s3Filename
  s3Path


exports.deleteContactImage = (s3Filename, callback) ->
  unless s3Filename then callback winston.makeMissingParamError 's3Filename'; return

  s3Path = imageUtils.getContactImageS3Path s3Filename
  s3Utils.deleteFile s3Path, callback