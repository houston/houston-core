class window.Kanban
  
  constructor: (projects)->
    @unfuddle = new Unfuddle()
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    projects = [projects] unless Object.isArray(projects)
    
    $('#on_deck .ticket').pseudoHover().popover
      title: 'Add Ticket'
      content: 'Click to add a ticket to the queue'
    
    for queueName in ['in_development', 'staged_for_testing', 'in_testing', 'staged_for_release']
      window.console.log(queueName)
      for project in projects
        color = project.color
        project = @unfuddle.project(project.id)
        @loadQueue(project, queueName, color)
  
  loadQueue: (project, queueName, color)->
    $queue = $("##{queueName}")
    report = project.queue(queueName)
    report.get (data)=>
      window.console.log(data)
      group0 = (data['groups'] || [])[0]
      tickets = if group0 then group0.tickets else []
      for ticket in tickets
        ticket.color = color
        $queue.append @renderTicket(ticket)
      
      $queue.find('.ticket').popoverForTicket().pseudoHover()
  
    