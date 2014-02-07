class RD.Model.User extends RD.Model.Base

  decorator: RD.Decorator.user

  getFullName: =>
    firstName = @get 'firstName'
    lastName = @get 'lastName'

    if firstName and lastName
      return firstName + ' ' + lastName
    else if firstName
      return firstName
    else if lastName
      return 'M. ' + lastName
    return ''