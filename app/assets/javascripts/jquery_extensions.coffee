$.fn.extend
  
  pseudoHover: ->
    $(@).hover(
      -> $(@).addClass('hover'),
      -> $(@).removeClass('hover'))
  
  popoverForTicket: ->
    $(@).popover
      title: -> $(@).find('.ticket-summary').html().split(': ')[0]
      content: -> $(@).find('.ticket-summary').html().split(': ')[1].capitalize()
  
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
