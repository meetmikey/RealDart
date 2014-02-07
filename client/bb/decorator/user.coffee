class RDUserDecorator
  
  decorate: (model) =>
    object = {}
    object.fullName = model.getFullName()
    object

RD.Decorator.user = new RDUserDecorator()