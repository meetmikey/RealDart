class RD.View.Contacts extends RD.View.Base

  contacts: null

  preRenderAsync: (callback) =>
    path = 'contacts'
    RD.Helper.api.get path, {}, (error, responseData) =>
      if error then callback('get contacts failed'); return
      unless responseData?.contacts then callback('invalid api response'); return

      @contacts = new RD.Collection.ContactSummary responseData.contacts

      rdLog 'got contacts...',
        contactsSize: @contacts.size()

      callback()


  getTemplateData: =>
    contacts: _.invoke @contacts.models, 'decorate'