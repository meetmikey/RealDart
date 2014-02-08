class RD.View.Home extends RD.View.Base

  getTemplateData: =>
    isLoggedIn: RD.Global.user?