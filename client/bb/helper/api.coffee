class RDHelperAPI

  tokenLocalStorageKey: 'token'

  postAuth: (path, data, callback) =>
    @_call 'post', path, data, true, callback

  post: (path, data, callback) =>
    @_call 'post', path, data, false, callback

  get: (path, data, callback) =>
    @_call 'get', path, data, false, callback


  buildURL: (path, isAuth) =>
    unless path
      rdWarn 'Helper.API:buildURL: path missing'
      return ''

    url = 'http'
    if RD.config.api.useSSL
      url += 's'
    url += '://' + RD.config.api.host
    if RD.config.api.port
      url += ':' + RD.config.api.port
    if not isAuth
      url += '/api'
    if path[0] isnt '/'
      url += '/'
    url += path
    url

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
    responseText = jqXHR.responseText
    responseCode = jqXHR.status

    if successOrError is 'success'
      if isAuth
        @_storeAuthToken responseText
      callback null, responseText
    else
      #in error case, send the responseCode as the error
      callback responseCode, responseText

  _getAuthToken: =>
    token = RD.Helper.localStorage.get @tokenLocalStorageKey
    token

  _storeAuthToken: (responseText) =>
    unless responseText
      return

    try
      responseJSON = JSON.parse responseText
      if responseJSON and responseJSON.token
        token = responseJSON.token
        RD.Helper.localStorage.set @tokenLocalStorageKey, token
    catch exception
      rdError 'exception during api token extraction',
        exception: exception

RD.Helper.API = new RDHelperAPI()