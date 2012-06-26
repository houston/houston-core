window.App = 
  
  relativeRoot: ->
    relativeRoot = $('meta[name="relative_url_root"]').attr('value')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    relativeRoot
