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
    data =
      user: @user?.decorate()
      linkedInStatus: @linkedInStatus
      facebookStatus: @facebookStatus

    rdLog 'getTemplateData',
      data: data

    data

  addMessageListener: =>
    window.addEventListener 'message', @receiveMessage, false

  removeMessageListener: =>
    window.removeEventListener 'message', @receiveMessage

  receiveMessage: (event) =>

    rdLog 'receiveMessage',
      event: event

    if event.origin isnt RD.Helper.API.getProtocolHostAndPort()
      return

    responseJSON = RD.Helper.API.getJSONFromText event.data
    service = responseJSON?.service
    status = responseJSON?.status

    rdLog 'service + status',
      service: service
      status: status

    unless status and service
      return

    if service is 'facebook'
      @facebookStatus = status
    if service is 'linkedIn'
      @linkedInStatus = status

    @renderTemplate()