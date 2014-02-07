class RD.View.Account extends RD.View.Base

  user: null
  linkedInStatus: null
  facebookStatus: null

  preInitialize: =>
    @getUser()
    @addMessageListener()

  teardown: =>
    @removeMessageListener()

  getUser: =>
    RD.Helper.API.get 'user', {}, (errorCode, response) =>
      if errorCode then @bail(); return
      unless response?.user then @bail(); return
      
      @user = new RD.Model.User response.user
      if @user.fbUserId
        @facebookStatus = 'success'
      if @user.liUserId
        @linkedInStatus = 'success'
      @renderTemplate()

  getTemplateData: =>
    user: @user?.decorate()
    linkedInStatus: @linkedInStatus
    facebookStatus: @facebookStatus

  addMessageListener: =>
    window.addEventListener 'message', @receiveMessage, false

  removeMessageListener: =>
    window.removeEventListener 'message', @receiveMessage

  receiveMessage: (event) =>
    if event.origin isnt RD.Helper.API.getProtocolHostAndPort()
      return

    responseJSON = RD.Helper.API.getJSONFromText event.data
    service = responseJSON?.service
    status = responseJSON?.status

    unless status and service
      return

    if service is 'facebook'
      @facebookStatus = status
    if service is 'linkedIn'
      @linkedInStatus = status

    @renderTemplate()