class RDContactDecorator
  
  decorate: (model) =>
    object = {}
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.picURL = model.get 'picURL'
    object.emails = model.get 'emails'
    object

RD.Decorator.contact = new RDContactDecorator()