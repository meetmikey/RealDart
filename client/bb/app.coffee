$(document).ready () ->
  RD.router = new RD.Router()
  Backbone.history.start()
  RD.Helper.validator.init()