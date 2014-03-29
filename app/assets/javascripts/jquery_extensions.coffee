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
  
  getCursorPosition: ->
    input = @get(0)
    return unless input
    if input.selectionStart # Standard-compliant browsers
      input.selectionStart
    else if document.selection # IE
      input.focus()
      sel = document.selection.createRange()
      selLen = document.selection.createRange().text.length
      sel.moveStart 'character', -input.value.length
      sel.text.length - selLen
  
  appendAsAlert: ->
    $alerts = $('#body .alert')
    $newAlert = $(@)
    if $alerts.length > 0
      $('#body .alert').fadeOut
        complete: ->
          $(@).remove()
          $newAlert.prependTo($('#body')).alert()
    else
      $newAlert.prependTo($('#body')).alert()
  
  putCursorAtEnd: ->
    @each ->
      $(@).focus()
      
      # If this function exists...
      if @setSelectionRange
        # ... then use it (Doesn't work in IE)
        
        # Double the length because Opera is inconsistent about whether a carriage return is one character or two. Sigh.
        len = $(@).val().length * 2
        
        @setSelectionRange(len, len)
      else
        
        # ... otherwise replace the contents with itself
        # (Doesn't work in Google Chrome)
        
        $(@).val($(@).val())



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
