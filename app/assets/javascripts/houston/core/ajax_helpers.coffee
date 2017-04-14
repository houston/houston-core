$.extend

  # Extend jQuery with functions for PUT and DELETE requests.
  put: (url, data, callback, type)->
    if jQuery.isFunction(data)
      callback = data
      data = {}

    data = data || {}
    data['_method'] = 'put'
    jQuery.post(url, data, callback, type)

  destroy: (url, data, callback, type)->
    if jQuery.isFunction(data)
      callback = data
      data = {}

    data = data || {}
    data._method = 'delete'
    jQuery.post(url, data, callback, type)



$(document).ajaxSend (e, jqxhr, settings)->
  return if settings.type is 'GET'
  jqxhr.setRequestHeader 'X-CSRF-Token', App.meta('csrf-token')
