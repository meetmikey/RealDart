class RDHelperAPI

  tokenLocalStorageKey: 'token'

  postAuth: (path, data, callback) =>
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
      rdWarn 'Helper.API:buildURL: path missing'
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
    responseJSON = @getJSONFromText jqXHR.responseText

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