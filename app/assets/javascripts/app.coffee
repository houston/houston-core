window.App = 
  
  meta: (name)->
    $("meta[name=\"#{name}\"]").attr('value')
  
  checkRevision: (jqXHR)->
    @clientRevision ||= App.meta('revision')
    serverRevision = jqXHR.getResponseHeader('X-Revision')
    unless @clientRevision == serverRevision
      window.console.log('[App.checkRevision] reloading...')
      window.location.reload()
  
  relativeRoot: ->
    relativeRoot = App.meta('relative_url_root')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    relativeRoot
