class RD.View.Account extends RD.View.Base

  user: null

  preInitialize: =>
    @getUser()

  getUser: =>
    RD.Helper.API.get 'user', {}, (errorCode, response) =>
      if errorCode then @bail(); return
      unless response?.user then @bail(); return
      
      @user = new RD.Model.User response.user
      @renderTemplate()

  getTemplateData: =>
    user: @user?.decorate()