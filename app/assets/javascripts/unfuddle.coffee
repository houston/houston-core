class window.Unfuddle
  
  project: (projectId)->
    new Unfuddle.Project(@, projectId)
  
  urlFor: (path)->
    relativeRoot = $('base').attr('href')
    "#{relativeRoot}/unfuddle#{path}.json"
  
  get:  (path, params)-> @ajax(path,  'GET', params)
  post: (path, params)-> @ajax(path, 'POST', params)
  put:  (path, params)-> @ajax(path,  'PUT', params)
  ajax: (path, method, params)->
    url = @urlFor(path)
    $.ajax url,
      method: method
