winston = require('./winstonWrapper').winston
imapConnect = require './imapConnect'

imapHelpers = this

exports.getMailBox = (googleUser, mailBoxType, callback) ->
  unless googleUser then callback winston.makeMissingParamError 'googleUser'; return
  unless googleUser.accessToken then callback winston.makeMissingParamError 'googleUser.accessToken'; return
  unless googleUser.email then callback winston.makeMissingParamError 'googleUser.email'; return

  accessToken = googleUser.accessToken
  email = googleUser.email

  imapConnect.createImapConnection email, accessToken, (error, imapConnection) ->
    if error then callback error; return
    unless imapConnection then callback winston.makeError 'no imapConnection'; return

    imapConnect.openMailBox imapConnection, mailBoxType, (error, mailBox) ->
      if error then callback error; return

      winston.doInfo 'mailBox opened!',
        mailBox: mailBox

      callback null, mailBox

exports.getHeaders = (userId, imapConnection, uidBatch, callback) ->
  unless userId then callback winston.makeMissingParamError 'userId'; return
  unless imapConnection then callback winston.makeMissingParamError 'imapConnection'; return
  unless uidBatch then callback winston.makeMissingParamError 'uidBatch'; return

  uidQuery = undefined
  if uidArray
    winston.doInfo 'getHeaders by array',
      uidArray: uidArray

    return callback()  unless uidArray.length
    uidQuery = uidArray
  else
    winston.doInfo "getHeaders in range",
      minUid: minUid
      maxUid: maxUid

    if not minUid or not maxUid or (maxUid isnt "*" and minUid > maxUid)
      return callback(winston.makeError("getHeaders validation error: minUid, maxUid invalid",
        userId: userId
        stateId: onboardingStateId
        minUid: minUid
        maxUid: maxUid
      ))
    uidQuery = minUid + ":" + maxUid
  currentLength = 0
  fetch = imapConn.fetch(uidQuery,
    bodies: "HEADER.FIELDS (MESSAGE-ID FROM TO CC BCC DATE X-IS-MIKEY)"
    size: true
  )
  
  # mail objects to be written to the databas
  docsToSave = []
  
  # mail objects to only map-reduce the contacts of
  docsForContactCounts = []
  fetch.on "message", (msg, uid) ->
    mailObject =
      userId: userId
      mailboxId: mailboxId

    prefix = "(#" + uid + ") "
    msg.on "body", (stream, info) ->
      buffer = ""
      count = 0
      stream.on "data", (chunk) ->
        count += chunk.length
        buffer += chunk.toString("utf8") #TODO: binary?
        return

      stream.once "end", ->
        if info.which isnt "TEXT"
          hdrs = Imap.parseHeader(buffer)
          mailObject["messageId"] = hdrs["message-id"]
          mailObject["isMikeyLike"] = true  if hdrs["x-is-mikey"] and hdrs["x-is-mikey"].length
          mailObject["sender"] = mailUtils.getSender(hdrs)
          mailObject["recipients"] = mailUtils.getAllRecipients(hdrs)
        return

      return

    msg.once "attributes", (attrs) ->
      mailObject["uid"] = attrs.uid
      mailObject["seqNo"] = attrs.seqno
      mailObject["size"] = attrs.size
      mailObject["gmDate"] = new Date(Date.parse(attrs["date"]))  if attrs["date"]
      mailObject.gmThreadId = attrs["x-gm-thrid"]  if attrs["x-gm-thrid"]
      mailObject.gmMsgId = attrs["x-gm-msgid"]  if attrs["x-gm-msgid"]
      if attrs["x-gm-labels"]
        mailObject.gmLabels = []
        attrs["x-gm-labels"].forEach (label) ->
          mailObject.gmLabels.push label
          return

      return

    msg.once "end", ->
      unless imapRetrieve.checkLabelIsInvalid(mailObject, folderNames)
        docsToSave.push mailObject  if isPremium or mailObject.gmDate.getTime() >= argDict.minDate.getTime()
        currentLength += 1
        
        # only update this during onboarding or new mail updates
        docsForContactCounts.push mailObject  unless isResumeDownloading
        
        # update min overall date (only during onboarding)
        if isOnboarding and mailObject.gmDate and mailObject.gmDate.getTime() < argDict.earliestEmailDate.getTime()
          winston.doInfo "update min date for user to ",
            date: mailObject.gmDate

          argDict.earliestEmailDate = mailObject.gmDate
          daemonUtils.markMinMailDateForUser argDict.userId, mailObject.gmDate
        unless mailObject.gmDate
          winston.doWarn "mailObject does not have a gmDate",
            mailObject: mailObject

      return

    return

  fetch.on "end", ->
    winston.doInfo "FETCH END",
      minUid: minUid
      maxUid: maxUid

    result =
      minUid: minUid
      maxUid: maxUid
      numMails: currentLength

    
    # we need to both save any docs worth saving and ensure that the
    # contact counts are updated prior
    async.parallel [
      (asyncCb) ->
        unless isResumeDownloading
          mrResults = imapRetrieve.mapReduceContactsInMemory(argDict.userId, argDict.userEmail, docsForContactCounts)
          imapRetrieve.incrementMapReduceValuesInDB mrResults, argDict.userId, argDict.userEmail, asyncCb
        else
          asyncCb()
      
      # save the docsToSave
      (asyncCb) ->
        if docsToSave.length is 0
          asyncCb()
        else
          MailModel.collection.insert docsToSave, (err) ->
            if err and err.code is 11000
              asyncCb()
            else if err
              asyncCb winston.makeError("Error from bulk insert",
                err: err
              )
            else
              asyncCb()
            return

    ], (err, results) ->
      if err
        callback err
      else
        if isOnboarding
          imapRetrieve.updateOnboardingStateModelWithHeaderBatch onboardingStateId, result, (err) ->
            if err
              callback err
            else
              callback()
            return

        else if isPremium and isResumeDownloading
          imapRetrieve.updateResumeDownloadModelWithHeaderBatch resumeDownloadingId, result, (err) ->
            if err
              callback err
            else
              callback()
            return

        else
          callback()
      return

    return

  fetch.on "error", (err) ->
    winston.doWarn "FETCH ERROR",
      msg: err.message
      stack: err.stack

    return

  return