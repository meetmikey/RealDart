class RD.Model.ContactSummary extends RD.Model.Base

  decorator: RD.Decorator.contactSummary

  getFullName: =>
    RD.Helper.utils.getFullName @get('firstName'), null, @get('lastName')