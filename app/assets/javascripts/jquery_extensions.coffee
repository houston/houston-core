$.fn.extend
  
  pseudoHover: ->
    $(@).hover(
      -> $(@).addClass('hover'),
      -> $(@).removeClass('hover'))
  
  popoverForTicket: ->
    $(@).popover
      title: -> $(@).find('.ticket-summary').html().split(': ')[0]
      content: -> $(@).find('.ticket-summary').html().split(': ')[1].capitalize()
