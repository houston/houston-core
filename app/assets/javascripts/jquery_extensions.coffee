$.fn.extend
  
  pseudoHover: ->
    $(@).addClass('unhovered').hover(
      -> $(@).addClass('hover').removeClass('unhovered'),
      -> $(@).removeClass('hover').addClass('unhovered'))
  
  popoverForTicket: ->
    $queue = $(@).closest('ul')
    queue = $queue.attr('id')
    placement = if queue in ['staged_for_testing', 'in_testing', 'in_testing_production'] then 'left' else 'right'
    is_manual_queue = $queue.closest('.kanban-column').hasClass('manual')
    $(@).popover
      placement: placement
      title: -> 
        $(@).attr('data-project')
      content: ->
        content = $(@).find('.ticket-summary').html().split(': ')
        content = if content[1] then "<strong>#{content[0]}: </strong>#{content[1]}" else content[0]
        if is_manual_queue then content + '<span class="remove-instructions">Shift + Click to remove</span>' else content
  
  illustrateTicketVerdict: ->
    $(@).each ->
      $ticket = $(@)
      # <li class="ticket" data-tester-1="failing">...</li>
      if $ticket.is('[data-tester-1]')
        $el = $('<div class="ticket-badge"></div>')
        if $ticket.hasClass('failing')
          $el.appendTicketBadge('failing')
        else if $ticket.hasClass('passing')
          $el.appendTicketBadge('passing')
        $ticket.find('a').append $el
        testers = window.testers.length
        for i in [1..testers]
          verdict = $ticket.attr("data-tester-#{i}")
          new Badge($el, i, testers, verdict) if verdict
  
  appendTicketBadge: (status)->
    $(@).append("<img src=\"#{App.relativeRoot()}/images/badge-#{status}.png\" width=\"38\" height=\"38\" style=\"opacity: 0.3;\" />")
  
  appendView: (view)->
    el = @append(view.el)
    view.render()
    el
  
  prependView: (view)->
    el = @prepend(view.el)
    view.render()
    el
  
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
  
  disable: ->
    $(@).find('input[type="submit"], input[type="reset"], button').attr('disabled', 'disabled').end()
  
  enable: ->
    $(@).find('input[type="submit"], input[type="reset"], button').removeAttr('disabled').end()



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
