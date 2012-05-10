window.App = 
  
  relativeRoot: ->
    relativeRoot = $('base').attr('href')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    relativeRoot
