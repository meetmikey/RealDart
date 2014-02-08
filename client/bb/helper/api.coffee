class RDHelperAPI

  tokenLocalStorageKey: 'token'

  postAuth: (path, data, callback) =>
    #About to post an auth call (either login or register).
    #Clear any user data first, to be safe.
    RD.Helper.user.clearUser()
    @_call 'post', path, data, true, callback

  post: (path, data, callback) =>
    @_call 'post', path, data, false, callback

  get: (path, data, callback) =>
    @_call 'get', path, data, false, callback


  getProtocolHostAndPort: () ->
    apiConfig = RD.config.api
    result = 'http'
    if apiConfig.useSSL
      result += 's'
    result += '://'
    result += apiConfig.host
    if apiConfig.port
      result += ':' + apiConfig.port
    result

  buildURL: (path, isAuth) =>
    unless path
      rdWarn 'Helper.api:buildURL: path missing'
      return ''

    url = @getProtocolHostAndPort()
    if not isAuth
      url += '/api'
    if path[0] isnt '/'
      url += '/'
    url += path
    url

  getJSONFromText: (text) =>
    try
      json = JSON.parse text
    catch exception
      rdError 'exception during json parsing',
        exception: exception
      json = {}
    json

  deleteAuthToken: =>
    RD.Helper.localStorage.remove @tokenLocalStorageKey

  _call: (type, path, data, isAuth, callback) =>

    url = @buildURL path, isAuth

    ajaxOptions =
      data: data
      type: type
      complete: ( jqXHR, successOrError ) =>
        @_handleAjaxResponse jqXHR, successOrError, isAuth, callback

    token = @_getAuthToken()
    if token
      ajaxOptions.beforeSend = (xhr, settings) =>
        xhr.setRequestHeader 'Authorization', 'Bearer ' + token

    $.ajax url, ajaxOptions

  _handleAjaxResponse: ( jqXHR, successOrError, isAuth, callback ) =>
    errorCode = jqXHR.status
    responseJSON = @getJSONFromText jqXHR.responseText

    if successOrError isnt 'success'
      #in error case, send the errorCode as the error
      callback errorCode, responseJSON

    else
      #if successful, we set the errorCode to null
      errorCode = null

      if isAuth
        @_storeAuthToken responseJSON
        #Go ahead and get the user, so it goes into RD.Global.user before we callback
        RD.Helper.user.getUser true, (getUserErrorCode, user) =>
          callback errorCode, responseJSON
      else
        callback errorCode, responseJSON

  _getAuthToken: =>
    token = RD.Helper.localStorage.get @tokenLocalStorageKey
    token

  _storeAuthToken: (responseJSON) =>
    unless responseJSON and responseJSON.token
      return
    token = responseJSON.token
    RD.Helper.localStorage.set @tokenLocalStorageKey, token

RD.Helper.api = new RDHelperAPI()