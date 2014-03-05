class RDContactSummaryDecorator
  
  decorate: (model) =>
    object = {}
    object._id = model.get '_id'
    object.fullName = model.getFullName()
    object.primaryEmail = model.get 'primaryEmail'
    object.imageURL = @getImageURL model
    object.fbUser = model.get 'fbUser'
    object.liUser = model.get 'liUser'
    object.numTouches = model.get 'numTouches'
    object

  getImageURL: (model) =>
    unless model then return ''

    imageURLs = model.get 'imageURLs'
    if imageURLs and imageURLs.length
      return imageURLs[0]
    return ''

RD.Decorator.contactSummary = new RDContactSummaryDecorator()