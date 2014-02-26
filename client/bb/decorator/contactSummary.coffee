class RDContactSummaryDecorator
  
  decorate: (model) =>
    object = {}
    object._id = model.get '_id'
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.picURL = model.get 'picURL'
    object.fbUser = model.get 'fbUser'
    object.liUser = model.get 'liUser'
    object.numTouches = model.get 'numTouches'
    object

RD.Decorator.contactSummary = new RDContactSummaryDecorator()