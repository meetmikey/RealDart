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
    responseCode = jqXHR.status
    responseText = jqXHR.responseText
    
    try
      responseJSON = JSON.parse responseText
    catch exception
      rdError 'exception during response parsing',
        exception: exception
      responseJSON = {}

    if successOrError is 'success'
      if isAuth
        @_storeAuthToken responseJSON
      callback null, responseJSON
    else
      #in error case, send the responseCode as the error
      callback responseCode, responseJSON

  _getAuthToken: =>
    token = RD.Helper.localStorage.get @tokenLocalStorageKey
    token

  _storeAuthToken: (responseJSON) =>
    unless responseJSON and responseJSON.token
      return
    token = responseJSON.token
    RD.Helper.localStorage.set @tokenLocalStorageKey, token

RD.Helper.API = new RDHelperAPI()