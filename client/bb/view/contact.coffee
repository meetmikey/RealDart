class RD.View.Contact extends RD.View.Base

  bailPath: 'home'
  contact: null

  preRenderAsync: (callback) =>
    unless @contactId then callback 'no contactId'; return

    path = 'contact/' + @contactId
    RD.Helper.api.get path, {}, (error, responseData) =>
      if error then callback('get contact failed'); return
      unless responseData?.contact then callback('invalid api response'); return

      @contact = new RD.Model.Contact responseData.contact
      callback()


  getTemplateData: =>
    contact: @contact.decorate()