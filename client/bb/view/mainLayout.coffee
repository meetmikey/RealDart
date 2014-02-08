class RD.View.MainLayout extends RD.View.Base

  #only necessary for this guy since all other views are subViews.
  templateName: 'mainLayout'

  subViewDefinitions:
    header:
      viewClassName: 'MainLayout.Header'
      selector: '#rdHeader'
    footer:
      viewClassName: 'MainLayout.Footer'
      selector: '#rdFooter'

  preInitialize: =>
    @setElement $ '#rdContainer'

  preRenderAsync: (callback) =>
    @getUser callback

  getUser: (callback) =>
    RD.Helper.user.getUser false, (error, user) =>
      callback()

  #useful for login/logout events
  renderHeader: =>
    @renderSubView 'header'