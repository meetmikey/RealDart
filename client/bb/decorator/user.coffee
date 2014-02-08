class RDUserDecorator
  
  decorate: (model) =>
    object = {}
    object.firstName = model.get 'firstName'
    object.lastName = model.get 'lastName'
    object.email = model.get 'email'
    object.fullName = model.getFullName()
    object

RD.Decorator.user = new RDUserDecorator()