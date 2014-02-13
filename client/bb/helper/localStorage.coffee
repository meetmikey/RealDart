class RDHelperLocalStorage

  constructor: (@args) ->
    @store = window.localStorage

  supportsLocalStorage: ->
    typeof window.localStorage isnt 'undefined'

  getKey: (key) =>
    fullKey = 'RD-' + key
    fullKey

  get: (key) =>
    raw = @store.getItem @getKey key
    try #temporary to accomodate a snafu with setting the beta key
      val = JSON.parse raw
      return val
    catch e
      rdError 'local storage get exception'
      return raw

  set: (key, value) =>
    fullKey = @getKey key
    jsonValue = JSON.stringify value
    @store.setItem fullKey, jsonValue

  remove: (key) =>
    @store.removeItem @getKey key

  clear: =>
    @store.clear()

RD.Helper.localStorage = new RDHelperLocalStorage()