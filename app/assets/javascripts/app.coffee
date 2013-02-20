window.App = 
  
  meta: (name)->
    $("meta[name=\"#{name}\"]").attr('value')
  
  checkRevision: (jqXHR)->
    @clientRevision ||= App.meta('revision')
    serverRevision = jqXHR.getResponseHeader('X-Revision')
    if serverRevision
      if (@clientRevision != serverRevision)
        window.console.log("[App.checkRevision] reloading ('#{@clientRevision}' != '#{serverRevision}')")
        window.location.reload()
    else
      window.console.log("[App.checkRevision] serverRevision is blank")
  
  relativeRoot: ->
    relativeRoot = App.meta('relative_url_root')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    relativeRoot
  
  emojify: (string)->
    string.replace /:([a-z0-9\+\-_]+):/, (match, $1)->
      if _.contains(Emoji.names, $1)
        "<img alt=\"#{$1}\" height=\"20\" width=\"20\" src=\"#{App.relativeRoot()}/images/emoji/#{$1}.png\" class=\"emoji\" />"
      else
        match
