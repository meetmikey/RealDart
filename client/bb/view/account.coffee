class RD.View.Account extends RD.View.Base

  postRender: =>
    RD.Helper.API.get 'test', {}, (errorCode, response) ->
      rdLog 'test response',
        errorCode: errorCode
        response: response