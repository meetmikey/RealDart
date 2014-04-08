#template configuration file, values filled in should not be commited to repo

_getAWSPrefix = () ->
  if process.env.AWS_PREFIX
    return process.env.AWS_PREFIX
  return process.env.NODE_ENV

module.exports =
  environment: process.env.NODE_ENV
  debugMode: true
  auth:
    facebook:
      app_secret: '<secret>'
      app_id: '<app_id>'
    linkedIn:
      apiKey: '<apiKey>'
      apiSecret: '<apiSecret>'
      scope: [
        'r_fullprofile'
        'r_emailaddress'
        'r_network'
        'r_contactinfo'
      ]
    google:
      clientId: '<clientId>'
      clientSecret: ''
      accessType: 'offline'
      scope: [
        'https://www.googleapis.com/auth/userinfo.profile'
        'https://www.googleapis.com/auth/userinfo.email'
        'https://mail.google.com/'
        'https://www.google.com/m8/feeds'
      ]
      maxContactResultsPerQuery: 500
      baseOAuthPath: 'https://accounts.google.com/o/oauth2'
  sendingEmailAddress: '"RealDart" <noreply@realdart.com>'
  queue:
    addEmailTouches: 'addEmailTouches'
    dataImport: 'dataImport'
    graveyard: 'graveyard'
    importContactImages: 'importContactImages'
    mergeContacts: 'mergeContacts'
    mailDownload: 'mailDownload'
    mailHeaderDownload: 'mailHeaderDownload'
  aws:
    accountId: ''
    key: ''
    secret: ''
    region: ''
    ses:
      apiVersion: '2010-12-01'
      charSet: 'UTF-8'
    sqs:
      apiVersion: '2012-11-05'
      queueNamePrefix: _getAWSPrefix()
      host: 'sqs.us-west-2.amazonaws.com'
    s3:
      bucket: _getAWSPrefix() + '-realdart'
      region: 'us-west-2'
      folder:
        contactImage: 'contactImage'
  email:
    itAddress: 'it@mikeyteam.com'
    noReplyAddress: 'noreply@mikeyteam.com'
  mongo:
    prod:
      host : ''
      db: ''
      user: ''
      pass: ''
      port: 12345
    local:
      host: 'localhost'
      db: 'realdart'
      user: 'mikey'
      port: 27017
  crypto:
    aes:
      scheme: 'aes-256-cbc'
      secret: '<aes secret>' # encryption key len should be 256 bits
  gmail:
    imapParams:
      host: 'imap.gmail.com'
      port: 993
      tls: true
      tlsOptions:
        rejectUnauthorized: false
      connTimeout: 60000
    mailBoxNames:
      sent: #should match constants.mailBoxType.SENT
        capitalizedMailBoxName: 'SENTMAIL'
        slashedMailBoxName: "\\Sent"
    headerFieldsToFetch: [
      'MESSAGE-ID'
      'TO'
      'CC'
      'BCC'
      'DATE'
      'SUBJECT'
    ]
  google_apis:
    key : '<google api key>'

  turnDebugModeOff: () ->
    module.exports.debugMode = false
  turnDebugModeOn: () ->
    module.exports.debugMode = true