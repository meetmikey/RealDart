class RD.Router extends Backbone.Router

  _layout: null

  routes:
    '': 'home'
    'home': 'home'
    'login': 'login'
    'register': 'register'
    'account': 'account'
    'contacts': 'contacts'
    'contact/:contactId': 'contact'

  initialize: =>

  home: =>
    @render 'Home'

  login: =>
    @render 'Login'

  register: =>
    @render 'Register'

  account: =>
    @render 'Account'

  contacts: =>
    @render 'Contacts'

  contact: (contactId) =>
    @render 'Contact',
      contactId: contactId

  renderLayout: =>
    unless @_layout
      @_layout = new RD.View.MainLayout()
      @_layout.render()

  #useful for login/logout events
  renderHeader: =>
    unless @_layout
      return
    @_layout.renderHeader()

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