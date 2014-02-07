class RealDart.Router extends Backbone.Router

  _layout: null

  routes:
    '': 'home'
    'home': 'home'
    'login': 'login'
    'register': 'register'
    'account': 'account'

  initialize: =>

  home: =>
    @render 'Home'

  login: =>
    @render 'Login'

  register: =>
    @render 'Register'

  account: =>
    @render 'Account'

  renderLayout: =>
    unless @_layout
      @_layout = new RealDart.View.MainLayout()
      @_layout.render()

  scrollToTop: =>
    $('html, body').animate { scrollTop: 0 }, 'slow'

  render: (viewClassName, data) =>
    @renderLayout()
    @_layout.teardownSubView 'rdContent'
    @_layout.addAndRenderSubview 'rdContent', {
        viewClassName: viewClassName
        selector: '#rdContent'
      }, data
    @scrollToTop()