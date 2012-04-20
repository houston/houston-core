class window.Kanban
  
  constructor: (options)->
    @projects = options.projects
    @queues = options.queues
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    @observer = new Observer()
    
    # Ticket description popover
    $('.kanban-column').each ->
      $(@).find('.ticket').popoverForTicket().pseudoHover()
    
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
    relativeRoot = $('base').attr('href')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    "#{relativeRoot}/kanban/#{path}.json"
  
  get:  (path, params)-> @ajax(path,  'GET', params)
  post: (path, params)-> @ajax(path, 'POST', params)
  put:  (path, params)-> @ajax(path,  'PUT', params)
  ajax: (path, method, params)->
    url = @urlFor(path)
    $.ajax url,
      method: method
