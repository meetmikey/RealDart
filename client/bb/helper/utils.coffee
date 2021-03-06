class RDHelperUtils

  capitalize: (input) ->
    unless input and ( input.length > 0 ) then return ''

    capitalized = input[0].toUpperCase() + input.slice 1
    capitalized

  uncapitalize: (input) ->
    unless input and ( input.length > 0 ) then return ''

    capitalized = input[0].toLowerCase() + input.slice 1
    capitalized

  getClassFromName: (className) =>
    @getObjectFromString className

  getObjectFromString: (str) =>
    strArray = str.split '.'

    obj = window || this
    _.each strArray, (strArrayElement) =>
      obj = obj[strArrayElement]
    obj

  isUndefined: (input) ->
    if typeof input is 'undefined'
      return true
    return false

  getFullName: (firstName, middleName, lastName) =>
    if firstName and lastName
      return firstName + ' ' + lastName
    else if firstName
      return firstName
    else if lastName
      return 'M. ' + lastName
    return ''

RD.Helper.utils = new RDHelperUtils()