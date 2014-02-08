#NOTE: this class relies on RD.Helper.api, which just happens to load first
  # based on the alphabetical ordering of the filenames.  We could make this explicit
  # in the gruntfile if we needed to change it.

class RDHelperUser

  getUser: (forceFetch, callback) =>
    if RD.Global.user and not forceFetch
      return RD.Global.user

    RD.Helper.api.get 'user', {}, (errorCode, response) =>
      if errorCode then callback ''; return
      unless response?.user then callback 'missing user'; return

      @setUser new RD.Model.User response.user

      callback errorCode, RD.Global.user

  setUser: (user) =>
    RD.Global.user = user

  clearUser: =>
    RD.Global.user = null
    RD.Helper.api.deleteAuthToken()

  logout: () =>
    @clearUser()
    RD.router.navigate 'login',
      trigger: true
    RD.router.renderHeader()

  doAuth: (apiCall, data, callback) =>
    RD.Helper.api.postAuth apiCall, data, (errorCode, response) =>
      if errorCode
        if errorCode < 500
          callback response?.error
        else
          callback 'server error'
      else
        callback()

RD.Helper.user = new RDHelperUser()