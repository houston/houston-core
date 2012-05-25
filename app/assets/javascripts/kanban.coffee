class window.Kanban
  
  constructor: (options)->
    @projects = options.projects
    @queues = options.queues
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    @observer = new Observer()
    self = @
    
    # Make the Kanban fill the browser window
    @kanban = $('#kanban')
    @window = $(window)
    @top = @naturalTop = @kanban.offset().top
    @window.resize => @setKanbanSize()
    @setKanbanSize()
    
    # Style alternating columns
    @kanban.find('thead tr th:even, tbody tr td:even, tfoot tr th:even').addClass('alt')
    
    # Fix the Kanban to the bottom of the window
    # after determining its natural top.
    @kanban.css('bottom': '0px')
    
    # It might be nice to calculate this
    @standardTicketWidth = Math.ceil(72 + 4.55) # px
    @standardTicketHeight = Math.ceil(55 + 4.55) # px
    
    # Set the size of tickets initially
    # Ticket description popover
    $('.kanban-column').each ->
      self.resizeColumn $(@).find('ul:first')
      $(@).find('.ticket').popoverForTicket().pseudoHover()
    
    # Resize the tickets in a column when the window resizes
    $(window).resize ->
      $('.kanban-column ul').each ->
        self.resizeColumn $(@)
  
  observe: (name, func)-> @observer.observe(name, func)
  unobserve: (name, func)-> @observer.unobserve(name, func)
  
  loadQueues: ->
    for queueName in @queues
      for project in @projects
        @loadQueue(project, queueName)
  
  loadQueue: (project, queueName)->
    $queue = $("##{queueName}")
    @fetchQueue project, queueName, (tickets)=>
      
      # Remove existing tickets
      $queue.find(".#{project.slug}").remove()
      
      for ticket in tickets
        $queue.append @renderTicket(ticket)
      
      @resizeColumn $queue
      
      $queue.find('.ticket')
        .popoverForTicket()
        .pseudoHover()
        .illustrateTicketVerdict()
      
      @observer.fire('queueLoaded', [queueName, project])
  
  fetchQueue: (project, queueName, callback)->
    xhr = @get "#{project.slug}/#{queueName}"
    xhr.error ->
      window.console.log('error', arguments)
    xhr.success (data)->
      window.console.log(data)
      callback(data)
  
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
  
  urlFor: (path)->
    "#{App.relativeRoot()}/kanban/#{path}.json"
  
  get:  (path, params)-> @ajax(path,  'GET', params)
  post: (path, params)-> @ajax(path, 'POST', params)
  put:  (path, params)-> @ajax(path,  'PUT', params)
  ajax: (path, method, params)->
    url = @urlFor(path)
    $.ajax url,
      method: method
  
  resizeColumn: ($ul)->
    queue = $ul.attr('id')
    tickets = $ul.children().length
    
    $count = $("thead .kanban-column[data-queue=\"#{queue}\"]")
    $count.html("<strong>#{tickets}</strong> tickets")
    $count.toggleClass('zero', tickets == 0)
    
    return if tickets == 0
    
    # This is obviously imprecise.
    # 60 is for the admin stripe and its bottom margin
    # 32 is for the THEAD which lists the number of tickets in a queue
    height = $(window).height() - 60 - 32 - $('tfoot').height()
    width = $ul.width()
    # window.console.log("[layout] ##{queue} is", [width, height])
    
    ratio = 1
    ticketWidth = @standardTicketWidth
    ticketHeight = @standardTicketHeight
    ticketsThatFitHorizontally = Math.floor(width / ticketWidth)
    
    if isNaN(ticketsThatFitHorizontally)
      window.console.log "[layout] #{ticketsThatFitHorizontally} tickets fit into ##{queue}"
      return
    
    while true
      numberOfRowsRequired = Math.ceil(tickets / ticketsThatFitHorizontally)
      heightOfTickets = numberOfRowsRequired * ticketHeight
      break if heightOfTickets < height
      
      # What ratio is required to squeeze one more column of tickets
      # window.console.log "[layout] adding a column to ##{queue}, #{ticketsThatFitHorizontally} wasn't enough"
      ticketsThatFitHorizontally++
      ratio = width / (@standardTicketWidth * ticketsThatFitHorizontally)
      ticketWidth = @standardTicketWidth * ratio
      ticketHeight = @standardTicketHeight * ratio
    
    $ul.css('font-size': "#{ratio}em")
