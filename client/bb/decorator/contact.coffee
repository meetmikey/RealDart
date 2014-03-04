class RDContactDecorator
  
  decorate: (model) =>
    object = {}
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.image = @getImage model
    object.emails = model.get 'emails'
    object.numTouches = model.get 'numTouches'
    object

  getImage: (model) =>
    unless model then return ''

    images = model.get 'images'
    if images and images.length
      return images[0]
    return ''

RD.Decorator.contact = new RDContactDecorator()