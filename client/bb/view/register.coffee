class RD.View.Register extends RD.View.Base

  events:
    'submit #registerForm': 'register'

  postRender: =>
    @setupValidation()

  setupValidation: =>
    @$('#registerForm').validate
      rules:
        firstName:
          required: true
        lastName:
          required: true
        email:
          required: true
          email: true
        password:
          required: true
          minlength: RD.constant.MIN_PASSWORD_LENGTH
          checkPassword: true
        password2:
          required: true
          equalTo: '#password'

  register: (event) =>
    event.preventDefault()
    @hideError()

    data =
      firstName: @$('#firstName').val()
      lastName: @$('#lastName').val()
      email: @$('#email').val()
      password: @$('#password').val()

    RD.Helper.API.postAuth 'register', data, (errorCode, responseText) =>
      if errorCode 
        if errorCode < 500
          @showError responseText
        else
          @showError 'server error'
      else
        RD.router.navigate 'account',
          trigger: true

    #prevent form submission
    false

  getErrorElement: =>
    @$('#registerError')

  showError: (error) =>
    @getErrorElement().html error
    @getErrorElement().show()

  hideError: =>
    @getErrorElement().hide()