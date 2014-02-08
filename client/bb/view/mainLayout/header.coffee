class RD.View.MainLayout.Header extends RD.View.Base

  events:
    'click #logout': 'logout'

  getTemplateData: =>
    isLoggedIn: RD.Global.user?
    user: RD.Global.user?.decorate()

  logout: =>
    RD.Helper.user.logout()