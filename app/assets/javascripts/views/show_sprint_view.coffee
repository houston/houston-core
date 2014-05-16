class @ShowSprintView extends Backbone.View
  className: 'hide-completed'
  
  events:
    'click .check-out-button': 'toggleCheckOut'
    'click #show_completed_tickets': 'toggleShowCompleted'
    'click #lock_sprint_button': 'confirmLockSprint'
    'click .remove-ticket-button': 'removeTicket'
    'submit #add_ticket_form': 'addTicket'
  
  initialize: ->
    @sprintId = @options.sprintId
    @locked = @options.sprintLocked
    @template = HandlebarsTemplates['sprints/show']
    @typeaheadTemplate = HandlebarsTemplates['sprints/typeahead']
    @tickets = _.sortBy @options.sprintTickets, (ticket)-> ticket.projectTitle
    @openTickets = @options.openTickets
    super
  
  render: ->
    return @ unless @tickets
    html = @template
      locked: @locked
      tickets: @tickets
      sprintId: @sprintId
    @$el.html html
    
    if @locked
      @showAsLocked()
    else
      @$el.addClass 'edit-mode'
      $('#add_ticket').focus()
    
    @renderBurndownChart(@tickets)
    @updateTotalEffort()
    
    typeaheadTemplate = @typeaheadTemplate
    view = @
    $add_ticket = @$el.find('#add_ticket').attr('autocomplete', 'off').typeahead
      source: @openTickets
      matcher: (item)->
        return false if _.detect(view.tickets, (ticket)-> ticket.id == item.id)
        ~item.summary.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.projectTitle.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.number.toString().toLowerCase().indexOf(@query.toLowerCase())
      
      sorter: (items)-> items # apply no sorting (return them in order of priority)
      
      highlighter: (ticket)->
        query = @query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
        regex = new RegExp("(#{query})", 'ig')
        ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
        typeaheadTemplate
          sequence: ticket.extendedAttributes?.sequence
          summary: ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          number: ticket.number.toString().replace regex, ($1, match)-> "<strong>#{match}</strong>"
          projectTitle: ticket.projectTitle.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          projectColor: ticket.projectColor
    
    $add_ticket.data('typeahead').render = (tickets)->
      items = $(tickets).map (i, item)=>
        i = $(@options.item).attr('data-value', item.id)
        i.find('a').html(@highlighter(item))
        i[0]
      
      items.first().addClass('active')
      @$menu.html(items)
      @
    
    addTicket = _.bind(@addTicket, @)
    $add_ticket.data('typeahead').select = ->
      id = @$menu.find('.active').attr('data-value')
      @$element.val('')
      @hide()
      addTicket(id)
    
    
    
    $('.table-sortable').tablesorter()
    @
  
  
  
  addTicket: (id)->
    e?.preventDefault()
    $('#add_ticket_form').addClass('loading')
    
    $.post("/sprints/#{@sprintId}/tickets/#{id}")
      .error =>
        $('#add_ticket_form').removeClass('loading')
      .success (ticket)=>
        @tickets.push ticket
        @rerenderTickets()
        @renderBurndownChart(@tickets)
        $('#add_ticket_form').removeClass('loading')
  
  removeTicket: (e)->
    $button = $(e.target)
    $ticket = $button.closest('.ticket')
    id = +$ticket.attr('data-ticket-id')
    $.destroy("/sprints/#{@sprintId}/tickets/#{id}")
      .error =>
        $ticket.removeClass('deleting')
      .success (ticket)=>
        @tickets = _.reject(@tickets, (ticket)-> ticket.id == id)
        $ticket.remove()
        @renderBurndownChart(@tickets)
    
  rerenderTickets: ->
    template = HandlebarsTemplates['sprints/ticket']
    $tickets = @$el.find('#tickets').empty()
    for ticket in @tickets
      $tickets.append template(ticket)
  
  
  
  renderBurndownChart: (tickets)->
    
    # The time range of the Sprint
    today = new Date()
    daysSinceMonday = 1 - today.getWeekday()
    monday = @truncateDate daysSinceMonday.days().after(today)
    days = (i.days().after(monday) for i in [0..4])
    
    # Sum progress by day;
    # Find the total amount of effort to accomplish
    progressByDay = {}
    totalEffort = 0
    for ticket in tickets
      effort = +ticket.estimatedEffort
      if ticket.firstReleaseAt
        day = @truncateDate App.parseDate(ticket.firstReleaseAt)
        effort = 0 if day < monday # this ticket was released before this sprint started!
        progressByDay[day] = (progressByDay[day] || 0) + effort
      totalEffort += effort
    
    # for debugging
    window.progressByDay = progressByDay
    
    # Transform into remaining effort by day:
    # Iterate by day in case there are some days
    # where no progress was made
    remainingEffort = totalEffort - (progressByDay[monday] || 0)
    data = [
      day: monday
      effort: Math.ceil(remainingEffort)
    ]
    for day in days.slice(1)
      unless day > today
        remainingEffort -= (progressByDay[day] || 0)
        data.push
          day: day
          effort: Math.ceil(remainingEffort)
    
    margin = {top: 40, right: 80, bottom: 32, left: 50}
    width = 960 - margin.left - margin.right
    height = 320 - margin.top - margin.bottom
    formatDate = d3.time.format('%A')
    
    x = d3.scale.ordinal().rangePoints([0, width], 0.75).domain(days)
    y = d3.scale.linear().range([height, 0]).domain([0, totalEffort])
    
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat((d)-> formatDate(new Date(d)))
    
    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
    
    line = d3.svg.line()
      .interpolate('cardinal')
      .x((d)-> x(d.day))
      .y((d)-> y(d.effort))
    
    $('#graph').empty()
    svg = d3.select('#graph').append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")
    
    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{height})")
      .call(xAxis)
    
    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)
      .append('text')
        .attr('transform', 'rotate(-90)')
        .attr('y', -45)
        .attr('x', -160)
        .attr('dy', '.71em')
        .attr('class', 'legend')
        .style('text-anchor', 'end')
        .text('Points Remaining')
    
    svg.append('path')
      .attr('class', 'line')
      .attr('d', line(data))
    
    svg.selectAll('circle')
      .data(data)
      .enter()
      .append('circle')
        .attr('r', 5)
        .attr('cx', (d)-> x(d.day))
        .attr('cy', (d)-> y(d.effort))
    
    svg.selectAll('.effort-remaining')
      .data(data)
      .enter()
      .append('text')
        .text((d) -> d.effort)
        .attr('class', 'effort-remaining')
        .attr('transform', (d)-> "translate(#{x(d.day) + 5.5}, #{y(d.effort) - 10}) rotate(-75)")
  
  truncateDate: (date)->
    date.setHours(0)
    date.setMinutes(0)
    date.setSeconds(0)
    date.setMilliseconds(0)
    date
  
  
  
  toggleCheckOut: (e)->
    $button = $(e.target)
    $ticket = $button.closest('tr')
    id = +$ticket.attr('data-ticket-id')
    ticket = _.find @tickets, (ticket)-> ticket.id == id
    
    if $button.hasClass('active')
      @checkIn($button, $ticket, id, ticket)
    else
      @checkOut($button, $ticket, id, ticket)
  
  checkIn: ($button, $ticket, id, ticket)->
    $.destroy("/tickets/#{id}/lock")
      .success =>
        ticket.checkedOutAt = null
        ticket.checkedOutBy = null
        $button.removeClass('btn-danger').addClass('btn-info').html('Check out')
        @updateTotalEffort()
      .error (xhr)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().appendAsAlert()
  
  checkOut: ($button, $ticket, id, ticket)->
    $.post("/tickets/#{id}/lock")
      .success =>
        ticket.checkedOutAt = new Date()
        ticket.checkedOutBy =
          id: window.user.id
          name: window.user.get('name')
          email: window.user.get('email')
        $button.removeClass('btn-info').addClass('btn-danger').html('Check in')
        @updateTotalEffort()
      .error (response)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().appendAsAlert()

  updateTotalEffort: ->
    effort = 0
    for ticket in @tickets when ticket.checkedOutBy?.id == window.user.id
      effort += +ticket.estimatedEffort
    $('#total_effort').html(effort.toFixed(1))


  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')


  confirmLockSprint: ->
    return if @locked
    $modal = $("""
    <div class="modal hide" tabindex="-1">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Lock Sprint</h3>
      </div>
      <div class="modal-body">
        Once you lock a Sprint, you will be unable to add or remove tickets.
      </div>
      <div class="modal-footer">
        <button class="btn" data-dismiss="modal">Back away slowly</button>
        <button id="confirm_lock_sprint" class="btn btn-danger" data-dismiss="modal">
          <i class="icon icon-lock" /> Lock It!
        </button>
      </div>
    </div>
    """).modal()
    $modal.on 'hidden', -> $modal.remove()
    $('#confirm_lock_sprint').click _.bind(@lockSprint, @)
  
  lockSprint: ->
    $.put("/sprints/#{@sprintId}/lock")
      .success =>
        @locked = true
        @showAsLocked()
  
  showAsLocked: ->
    @$el.removeClass 'edit-mode'
    $('#lock_sprint_button')
      .attr('disabled', 'disabled')
      .addClass('active')
      .removeClass('btn-danger')
      .html('<i class="icon icon-lock" /> Locked')
