commonAppDir = process.env.REAL_DART_HOME + '/server/common/app'

Handlebars = require( commonAppDir + '/lib/handlebarsWrapper').Handlebars
winston = require(commonAppDir + '/lib/winstonWrapper').winston
sesUtils = require commonAppDir + '/lib/sesUtils'
eventDigestHelpers = require commonAppDir + '/lib/eventDigestHelpers'

commonConf = require commonAppDir + '/conf'

templates = require('./templates')(Handlebars)

sendEmailUtils = this


exports.sendEventDigestEmail = ( eventDigest, user, callback ) ->
  unless eventDigest then callback winston.makeMissingParamError 'eventDigest'; return
  unless user then callback winston.makeMissingParamError 'user'; return
  unless user.email then callback winston.makeMissingParamError 'user.email'; return

  eventDigestHelpers.getEventDigestEmailText eventDigest, user, (error, emailHTML) ->
    if error then callback error; return

    recipients = [user.email]
    sender = commonConf.sendingEmailAddress
    text = emailHTML
    html = emailHTML
    subject = 'Your daily RealDart'

    winston.doInfo 'about to send email...',
      recipients: recipients
      sender: sender
      text: text
      subject: subject

    #TEMP
    #callback winston.makeError 'temp error!'
    
    sesUtils.sendEmail recipients, sender, text, html, subject, callback


exports.getEmailTemplateHTML = (templateName, templateData) ->
  unless templateName then return ''

  winston.doInfo 'partials',
    partials: Handlebars.partials

  templateData = templateData || {}
  fullTemplateName = 'src/templates/' + templateName + '.html'
  emailTemplate = templates[fullTemplateName]
  emailHTML = emailTemplate templateData
  emailHTML