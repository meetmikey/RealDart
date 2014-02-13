class RD.View.Account extends RD.View.Base

  user: null
  serviceAuth:
    google:
      status: null
      imageName: 'connectEmail'
    facebook:
      status: null
      imageName: 'connectFacebook'
    linkedIn:
      status: null
      imageName: 'connectLinkedIn'

  events:
    'click .authLink': 'authLinkClicked'

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
        @serviceAuth.google.status = 'success'
      if @user.fbUserId
        @serviceAuth.facebook.status = 'success'
      if @user.liUserId
        @serviceAuth.linkedIn.status = 'success'
      callback()

  getTemplateData: =>
    user: @user?.decorate()
    serviceAuth: @serviceAuth

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

    unless status and service and @serviceAuth[service]
      return

    @serviceAuth[service].status = status
    @renderTemplate()

  authLinkClicked: (event) =>
    element = $ event?.currentTarget
    unless element then rdError 'authLinkClicked: no element'; return
    service = element.attr 'data-service'
    unless service then rdError 'authLinkClicked: no service'; return

    tokenLocalStorageKey = RD.Helper.localStorage.getKey RD.Helper.api.tokenLocalStorageKey
    url = '/preAuth/' + service
    window.open url