class RD.Model.User extends RD.Model.Base

  decorator: RD.Decorator.user

  getFullName: =>
    RD.Helper.utils.getFullName @get('firstName'), null, @get('lastName')