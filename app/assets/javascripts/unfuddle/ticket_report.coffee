class window.Unfuddle.TicketReport
  
  constructor: (@project, @id)->
  
  get: (callback)->
    xhr = @project.get "/ticket_reports/#{@id}"
    xhr.success callback
    xhr.error -> window.console.log('error', arguments)

