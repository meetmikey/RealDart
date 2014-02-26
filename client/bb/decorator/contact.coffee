class RDContactDecorator
  
  decorate: (model) =>
    object = {}
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object

RD.Decorator.contact = new RDContactDecorator()