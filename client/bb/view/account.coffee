class RD.View.Account extends RD.View.Base

  user: null
  googleStatus: null
  linkedInStatus: null
  facebookStatus: null

  preInitialize: =>
    @addMessageListener()

  teardown: =>
    @removeMessageListener()

  preRenderAsync: (callback) =>
    @getUser callback

  getUser: (callback) =>
    RD.Helper.user.getUser true, (error, user) =>
      if error or not user then callback('fail'); @bail(); return

      @user = user
      if @user.googleUserId
        @googleStatus = 'success'
      if @user.fbUserId
        @facebookStatus = 'success'
      if @user.liUserId
        @linkedInStatus = 'success'
      callback()

  getTemplateData: =>
    user: @user?.decorate()
    googleStatus: @googleStatus
    facebookStatus: @facebookStatus
    linkedInStatus: @linkedInStatus

  addMessageListener: =>
    window.addEventListener 'message', @receiveMessage, false

  removeMessageListener: =>
    window.removeEventListener 'message', @receiveMessage

  receiveMessage: (event) =>
    if event.origin isnt RD.Helper.api.getProtocolHostAndPort()
      return

    responseJSON = RD.Helper.api.getJSONFromText event.data
    service = responseJSON?.service
    status = responseJSON?.status

    unless status and service
      return

    if service is 'google'
      @googleStatus = status
    else if service is 'facebook'
      @facebookStatus = status
    else if service is 'linkedIn'
      @linkedInStatus = status

    @renderTemplate()