$.fn.extend

  pseudoHover: ->
    $(@).addClass('unhovered').hover(
      -> $(@).addClass('hover').removeClass('unhovered'),
      -> $(@).removeClass('hover').addClass('unhovered'))

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
