class RD.View.Login extends RD.View.Base

  events:
    'submit #loginForm': 'login'

  postRender: =>
    @setupValidation()

  setupValidation: =>
    @$('#loginForm').validate
      rules:
        email:
          required: true
          email: true
        password:
          required: true

  login: (event) =>
    event.preventDefault()
    @hideError()

    data =
      email: @$('#email').val()
      password: @$('#password').val()

    RD.Helper.user.doAuth 'login', data, (error) =>
      if error
        @showError error
      else
        RD.router.navigate 'account',
          trigger: true
        RD.router.renderHeader()
    
    #prevent form submission
    false

  getErrorElement: =>
    @$('#loginError')

  showError: (error) =>
    @getErrorElement().html error
    @getErrorElement().show()

  hideError: =>
    @getErrorElement().hide()