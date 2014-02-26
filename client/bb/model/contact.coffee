class RD.Model.Contact extends RD.Model.Base

  decorator: RD.Decorator.contact

  getFullName: =>
    RD.Helper.utils.getFullName @get('firstName'), null, @get('lastName')