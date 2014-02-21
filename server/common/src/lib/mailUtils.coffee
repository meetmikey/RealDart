mimelib = require 'mimelib'

winston = require('./winstonWrapper').winston
utils = require './utils'
basicUtils = require './basicUtils'

mailUtils = this


exports.getAllRecipients = (headers) ->
  toRecipients = []
  ccRecipients = []
  bccRecipients = []

  if headers.to and headers.to.length > 0
    toRecipients = mimelib.parseAddresses headers.to[0]
    mailUtils.renameAddressField toRecipients
  
  if headers.cc and headers.cc.length > 0
    ccRecipients = mimelib.parseAddresses headers.cc[0]
    mailUtils.renameAddressField ccRecipients
  
  if headers.bcc and headers.bcc.length > 0
    bccRecipients = mimelib.parseAddresses headers.bcc[0]
    mailUtils.renameAddressField bccRecipients
  
  allRecipients = toRecipients.concat(ccRecipients).concat(bccRecipients)
  for recipient, index in allRecipients
    allRecipients[index] = mailUtils.normalizeEmailAddress recipient
  allRecipients


exports.renameAddressField = (arr) ->
  for element in arr
    element['email'] = element['address']
    delete element['address']


exports.normalizeEmailAddress = (input) ->
  unless input and utils.isString( input ) then return ''

  output = input.trim().toLowerCase()
  atIndex = output.indexOf '@'
  
  unless atIndex > 0
    winston.doWarn 'normalizeEmailAddress: invalid email address',
      input: input
    return ''

  beforeAt = output.substring 0, atIndex
  afterAt = output.substring atIndex + 1

  plusIndex = beforeAt.indexOf '+'
  if plusIndex > 0
    beforeAt = beforeAt.substring 0, plusIndex

  beforeAt = beforeAt.replace /\./g, ''
  output = beforeAt + '@' + afterAt
  output


exports.getCleanSubject = (rawSubject) ->
  subject = rawSubject
  unless subject
    subject = ''
  
  prefixes = [
    'Re:'
    'Fwd:'
    ' '
    'Aw:'   #Apparently 'Aw:' is German for 'Re:'
  ]

  while utils.startsWithAPrefix subject, prefixes
    for prefix in prefixes
      if subject.toLowerCase().substring( 0, prefix.length ) is prefix.toLowerCase()
        subject = subject.substring( prefix.length ).trim()
        continue

  if subject
    subject = subject.trim()

  subject
