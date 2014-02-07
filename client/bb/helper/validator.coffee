class RDHelperValidator

  init: =>
    $.validator.setDefaults
      debug: RD.config.debugMode

    $.validator.addMethod 'checkPassword', @checkPassword, 'Must contain lower case, upper case, and a digit.'

  checkPassword: (value) ->
    # has an lowercase letter
    lowerCaseCheck = /[a-z]/.test value

    # has an uppercase letter
    upperCaseCheck = /[A-Z]/.test value

    # has a digit
    digitCheck = /\d/.test value

    isValid = lowerCaseCheck and upperCaseCheck and digitCheck
    isValid

RD.Helper.validator = new RDHelperValidator()