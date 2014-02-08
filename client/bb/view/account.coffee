class RD.View.Account extends RD.View.Base

  user: null
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
      if @user.fbUserId
        @facebookStatus = 'success'
      if @user.liUserId
        @linkedInStatus = 'success'
      callback()

  getTemplateData: =>
    user: @user?.decorate()
    linkedInStatus: @linkedInStatus
    facebookStatus: @facebookStatus

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

    if service is 'facebook'
      @facebookStatus = status
    if service is 'linkedIn'
      @linkedInStatus = status

    @renderTemplate()