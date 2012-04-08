class window.Unfuddle.Project
  
  constructor: (@unfuddle, @id)->
  
  ticketReport: (ticketReportId)->
    new Unfuddle.TicketReport(@, ticketReportId)
  
  queue: (name)->
    new Unfuddle.Queue(@, name)
  
  get: (path, callback)->
    if Object.isFunction(path)
      callback = path
      path = "/projects/#{@id}"
    else
      path = "/projects/#{@id}#{path}"
    
    xhr = @unfuddle.get path
    xhr.success callback
    xhr.error -> window.console.log('error', arguments)
  