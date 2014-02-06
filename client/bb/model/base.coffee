class RealDart.Model.Base extends Backbone.Model

  decorate: =>
    if @decorator
      return @decorator.decorate this
    return {}