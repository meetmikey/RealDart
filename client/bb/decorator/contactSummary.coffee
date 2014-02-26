class RDContactSummaryDecorator
  
  decorate: (model) =>
    object = {}
    object._id = model.get '_id'
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object

RD.Decorator.contactSummary = new RDContactSummaryDecorator()