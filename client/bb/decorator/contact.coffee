class RDContactDecorator
  
  decorate: (model) =>
    object = {}
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.imageURL = @getImageURL model
    object.emails = model.get 'emails'
    object.numTouches = model.get 'numTouches'
    object

  getImageURL: (model) =>
    unless model then return ''

    imageURLs = model.get 'imageURLs'
    if imageURLs and imageURLs.length
      return imageURLs[0]
    return ''

RD.Decorator.contact = new RDContactDecorator()