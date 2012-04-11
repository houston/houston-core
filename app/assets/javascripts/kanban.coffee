class window.Kanban
  
  constructor: (projects)->
    @unfuddle = new Unfuddle()
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    projects = [projects] unless Object.isArray(projects)
    
    # Ticket description popover
    $('#on_deck .ticket').pseudoHover().popover
      title: 'Add Ticket'
      content: 'Click to add a ticket to the queue'
    
    # Load queues
    for queueName in ['in_development', 'staged_for_testing', 'in_testing', 'staged_for_release']
      window.console.log(queueName)
      for project in projects
        color = project.color
        project = @unfuddle.project(project.id)
        @loadQueue(project, queueName, color)
    
    # Make the Kanban fill the browser window
    @kanban = $('#kanban')
    @window = $(window)
    @top = @naturalTop = @kanban.offset().top
    @window.resize => @setKanbanSize()
    @setKanbanSize()
    
    # Style alternating columns
    @kanban.find('tr td:even, tr th:even').addClass('alt')
    
    # Fix the Kanban to the bottom of the window
    # after determining its natural top.
    @kanban.css('bottom': '0px')
  
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
  
  setKanbanSize: ->
    height = @window.height() - @top
    @kanban.css(height: "#{height}px")
  
  showFullScreen: ->
    window.console.log('full screen')
    @top = 0
    @kanban.css('z-index': 2000)
    @setKanbanSize()
  
  showNormal: ->
    window.console.log('normal')
    @top = @naturalTop
    @kanban.css('z-index': '')
    @setKanbanSize()
      