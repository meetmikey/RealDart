class RDHelperAPI

  post: (path, data, callback) =>
    @_call 'post', path, data, callback

  get: (path, data, callback) =>
    @_call 'get', path, data, callback


  buildURL: (path) =>
    unless path
      rdWarn 'Helper.API:buildURL: path missing'
      return ''

    url = 'http'
    if RD.config.api.useSSL
      url += 's'
    url += '://' + RD.config.api.host
    if RD.config.api.port
      url += ':' + RD.config.api.port
    if path[0] isnt '/'
      url += '/'
    url += path
    url

  _call: (type, path, data, callback) =>
    
    url = @buildURL path
    $.ajax url,
      data: data
      type: type
      complete: ( jqXHR, successOrError ) ->
        responseText = jqXHR.responseText
        responseCode = jqXHR.status

        if successOrError is 'success'
          callback null, responseText
        else
          #in error case, send the responseCode as the error
          callback responseCode, responseText

RD.Helper.API = new RDHelperAPI()