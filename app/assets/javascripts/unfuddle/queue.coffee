class window.Unfuddle.Queue
  
  constructor: (@project, @name)->
  
  get: (callback)->
    xhr = @project.get "/#{@name}"
    xhr.success callback
    xhr.error -> window.console.log('error', arguments)

