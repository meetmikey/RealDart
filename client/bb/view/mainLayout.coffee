class RealDart.View.MainLayout extends RealDart.View.Base

  #only necessary for this guy since all other views are subViews.
  templateName: 'mainLayout'

  preInitialize: =>
    @setElement $ '#rdContainer'