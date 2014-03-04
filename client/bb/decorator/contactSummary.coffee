class RDContactSummaryDecorator
  
  decorate: (model) =>
    object = {}
    object._id = model.get '_id'
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.image = @getImage model
    object.fbUser = model.get 'fbUser'
    object.liUser = model.get 'liUser'
    object.numTouches = model.get 'numTouches'
    object

  getImage: (model) =>
    unless model then return ''

    images = model.get 'images'
    if images and images.length
      return images[0]
    return ''

RD.Decorator.contactSummary = new RDContactSummaryDecorator()