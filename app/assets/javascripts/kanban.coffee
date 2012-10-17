class window.Kanban
  
  constructor: (options)->
    @projects = options.projects
    @queues = options.queues
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    @observer = new Observer()
    self = @
    
    $('body').addClass('with-kanban')
    @el = $('#kanban')
    @window = $(window)
    @top = @naturalTop = @el.offset().top
    @setKanbanHeight()
    
    # Style alternating columns
    @el.find('thead tr th:even, tbody tr td:even, tfoot tr th:even').addClass('alt')
    
    # Fix the Kanban to the bottom of the window
    # after determining its natural top.
    @el.css('bottom': '0px')
    
    # It might be nice to calculate this
    # + 8 for 4px margin on all sides
    @standardTicketWidth = 2.7777778 * 18
    @standardTicketHeight = 1.8333333 * 18
    @standardPadding = 0.5 * 36
    @standardBorder = 0.1388889 * 36
    @standardMargin = 0.2222222 * 36
    
    # Set the size of tickets initially
    # Ticket description popover
    # window.console.log('[layout] init')
    $('.kanban-column').each ->
      $queue = $(@).find('ul:first')
      self.refreshQueue $queue
    
    # Allow refreshing a single column
    $('.refresh-queue').click ->
      $a = $(@)
      queueName = $a.attr('data-queue')
      $a.addClass('in-progress')
      self.loadQueues [queueName], =>
        $a.removeClass('in-progress')
    
    # Make the Kanban fill the browser window and scale tickets
    @window.resize(_.bind(@resize, @))
  
  observe: (name, func)-> @observer.observe(name, func)
  unobserve: (name, func)-> @observer.unobserve(name, func)
  
  loadQueues: (queuesNames=@queues, callback)->
    requests = []
    for queueName in queuesNames
      for project in @projects
        requests.push([project, queueName])
    
    nextRequest = =>
      request = requests.shift()
      if request
        [project, queueName] = request
        @loadQueue(project, queueName, nextRequest)
      else
        callback() if callback
    
    # Send two requests at a time
    nextRequest() if requests.length > 0
    nextRequest() if requests.length > 0
  
  loadQueue: (project, queueName, callback)->
    $queue = $("##{queueName}")
    @fetchQueue project, queueName, (tickets)=>
      
      # Remove existing tickets
      $queue.find(".#{project.slug}").remove()
      
      for ticket in tickets
        $queue.append @renderTicket(ticket)
      
      @refreshQueue $queue, ".ticket.#{project.slug}"
      
      @observer.fire('queueLoaded', [queueName, project])
      callback() if callback
  
  refreshQueue: ($queue, ticketSelector)->
    ticketSelector ?= '.ticket'
    $tickets = $queue.find(ticketSelector)
    
    $tickets
      .popoverForTicket()
      .pseudoHover()
    $tickets.illustrateTicketVerdict() if $queue.attr('id') == 'in_testing'
    
    @resizeColumn $queue
  
  fetchQueue: (project, queueName, callback)->
    xhr = @get "#{project.slug}/#{queueName}"
    xhr.error ->
      window.console.log('error', arguments)
    xhr.success (data, textStatus, jqXHR)->
      App.checkRevision(jqXHR)
      callback(data)
  
  showFullScreen: ->
    window.console.log('full screen')
    @top = 0
    @el.addClass('full-screen')
    @setKanbanHeight()
  
  showNormal: ->
    window.console.log('normal')
    @top = @naturalTop
    @el.removeClass('full-screen')
    @setKanbanHeight()
  
  urlFor: (path)->
    "#{App.relativeRoot()}/kanban/#{path}.json"
  
  get:  (path, params)-> @ajax(path,  'GET', params)
  post: (path, params)-> @ajax(path, 'POST', params)
  put:  (path, params)-> @ajax(path,  'PUT', params)
  ajax: (path, method, params)->
    url = @urlFor(path)
    $.ajax url,
      method: method
  
  resize: ->
    self = @
    @setKanbanHeight()
    $('.kanban-column ul').each ->
      self.resizeColumn $(@)
  
  setKanbanHeight: ->
    height = @window.height() - @top
    @el.css(height: "#{height}px")
  
  resizeColumn: ($ul)->
    queue = $ul.attr('id')
    tickets = $ul.children().length
    
    $count = $("thead .kanban-column[data-queue=\"#{queue}\"]")
    $count.find('.ticket-count').html("<strong>#{tickets}</strong> tickets")
    $count.toggleClass('zero', tickets == 0)
    
    return if tickets == 0
    
    $ul.removeClass('small-border')
    $ul.removeClass('small-margin')
    
    # This is obviously imprecise.
    # 60 is for the admin stripe and its bottom margin
    # 32 is for the THEAD which lists the number of tickets in a queue
    height = $(window).height() - 40 - 32 - $('tfoot').height()
    width = $ul.width()
    
    standardInnerWidth = @standardTicketWidth + @standardPadding
    standardTicketWidth = standardInnerWidth + @standardBorder + @standardMargin
    standardInnerHeight = @standardTicketHeight + @standardPadding
    standardTicketHeight = standardInnerHeight + @standardBorder + @standardMargin
    
    ratio = 1
    ticketWidth = standardTicketWidth
    ticketHeight = standardTicketHeight
    ticketsThatFitHorizontally = Math.floor(width / ticketWidth)
    
    if isNaN(ticketsThatFitHorizontally)
      window.console.log "[layout] #{ticketsThatFitHorizontally} tickets fit into ##{queue}"
      return
    
    while true
      numberOfRowsRequired = Math.ceil(tickets / ticketsThatFitHorizontally)
      heightOfTickets = numberOfRowsRequired * ticketHeight
      break if heightOfTickets < height
      
      # What ratio is required to squeeze one more column of tickets
      ticketsThatFitHorizontally++
      ticketWidth = Math.floor(width / ticketsThatFitHorizontally)
      ratio = ticketWidth / standardTicketWidth
      
      border = ratio * @standardBorder
      if border < 2
        $ul.addClass('small-border')
        border = 2
      
      margin = ratio * @standardMargin
      if margin < 2
        $ul.addClass('small-margin')
        margin = 2
      
      ratio = (ticketWidth - border - margin) / standardInnerWidth
      ticketHeight = (standardInnerHeight * ratio) + border + margin
    
    # window.console.log("[layout:#{queue}] column size: ", [width, height]) if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] ratio: #{ratio}") if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] tickets: #{ticketsThatFitHorizontally} rows x #{numberOfRowsRequired} cols") if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] ticket size: ", [ticketWidth, ticketHeight]) if queue == 'staged_for_testing'
    
    # At this point, get rid of the ticket age
    $ul.toggleClass('no-age', ratio < 0.666)
    
    # At this point, get rid of the ticket numbers
    $ul.toggleClass('no-number', ratio < 0.333)
    
    $ul.css('font-size': "#{ratio}em")
    $ul.find('.scale-me').css
      '-webkit-transform': "scale(#{ratio})"
      '-moz-transform': "scale(#{ratio})"
      '-m-transform': "scale(#{ratio})"
      'transform': "scale(#{ratio})"
