class RD.View.Contact extends RD.View.Base

  bailPath: 'home'
  contact: null
  fbUser: null
  liUser: null

  preRenderAsync: (callback) =>
    unless @contactId then callback 'no contactId'; return

    path = 'contact/' + @contactId
    RD.Helper.api.get path, {}, (error, responseData) =>
      if error then callback('get contact failed'); return
      unless responseData?.contact then callback('invalid api response'); return

      @contact = new RD.Model.Contact responseData.contact
      @fbUser = responseData?.fbUser
      @liUser = responseData?.liUser
      callback()


  getTemplateData: =>
    contact: @contact.decorate()
    fbUser: JSON.stringify @fbUser
    liUser: JSON.stringify @liUser
    jsonContact : JSON.stringify @contact