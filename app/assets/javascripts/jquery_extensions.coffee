$.fn.extend
  
  pseudoHover: ->
    $(@).hover(
      -> $(@).addClass('hover'),
      -> $(@).removeClass('hover'))
  
  popoverForTicket: ->
    queue = $(@).closest('ul').attr('id')
    placement = if queue in ['staged_for_testing', 'in_testing', 'in_testing_production'] then 'left' else 'right'
    is_staged_for_development = $(@).closest('ul').is '#staged_for_development'
    $(@).popover
      placement: placement
      title: -> 
        title = $(@).find('.ticket-summary').html().split(': ')
        if title[1] then title[0] else '<span class="no-feature">No Feature</span>'
      content: ->
        content = $(@).find('.ticket-summary').html().split(': ')
        content = if content[1] then content[1] else content[0]
        if is_staged_for_development then content + '<span class="remove-instructions">Shift + Click to remove</span>' else content.capitalize()
  
  illustrateTicketVerdict: ->
    $(@).each ->
      $ticket = $(@)
      if $ticket.hasClass('failing')
        $ticket.append('<div class="ticket-badge failing-ticket-badge"></div>')
      else if $ticket.hasClass('passing')
        $ticket.append('<div class="ticket-badge passing-ticket-badge"></div>')
  
  initializeAutoUpdate: (interval, kanban)->
    $(@).click ->
      $('#timer_wrapper').fadeIn()
      new Refresher
        time: interval
        callback: => kanban.loadQueues()
      $(@).remove()
  
  appendView: (view)->
    view.render()
    @append(view.el)
  
  serializeObject: ->
    o = {}
    a = @serializeArray()
    endsInArrayBrackets = /\[\]$/
    $.each a, ->
      if o[@name] && endsInArrayBrackets.test(@name)
        o[@name] = [o[@name]] unless o[@name].push
        o[@name].push(@value || '')
      else
        o[@name] = @value || ''
    o
  
  highlight: ->
    $(@).effect('highlight', {}, 1500)
  
  reset: ->
    $(@).each -> @reset()



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
