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