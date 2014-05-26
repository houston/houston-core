class @TicketModalView extends Backbone.View
  className: 'modal ticket-modal'

  initialize: ->
    @project = @options.project
    @tickets = @options.tickets
    @ticketNumbers = if @tickets then @tickets.pluck('number') else @options.ticketNumbers
    @onClose = @options.onClose
    @renderTaskView = @options.taskView
    @template = HandlebarsTemplates['tickets/modal']
    @renderTicket = HandlebarsTemplates['tickets/show']
    @$el.attr('tabindex', -1) # so that ESC works
    
    if @ticketNumbers
      @count = @ticketNumbers.length
      Mousetrap.bind 'up',  (e)=>
        if @$el.is(':visible')
          e.preventDefault()
          e.stopImmediatePropagation()
          @taskView?.saveChanges?()
          @show(@prev())
      Mousetrap.bind 'down', (e)=>
        if @$el.is(':visible')
          e.preventDefault()
          e.stopImmediatePropagation()
          @taskView?.saveChanges?()
          @show(@next())

  show: (number)->
    return unless number
    if @tickets
      @showTicket @tickets.findWhere(number: number)
    else
      $.get "/projects/#{@project}/tickets/by_number/#{number}.json", (json)=>
        @showTicket new Ticket(json)

  showTicket: (ticket)->
    @ticket = ticket
    @number = ticket.get 'number'
    @index = _.indexOf(@ticketNumbers, @number) if @ticketNumbers
    @render()

  render: ->
    @$el.html @template
      ticket: @renderTicket(@ticket.toJSON())
      index: @index + 1
      count: @count
    
    $modal = @$el.modal()
    $('body').addClass('noscroll')
    $modal.find('[title]').tooltip
      placement: 'bottom'
    
    @taskView = @renderTaskView?(@$el.find('.task-frame')[0], @ticket)
    @$el.find('.ticket-body').toggleClass 'show-task-frame', @taskView
    @taskView?.render()
    
    $modal.on 'hidden', (e)->
      if $modal[0] == e.target
        $modal.remove()
        $('body').removeClass('noscroll')
        @onClose() if @onClose

  next: ->
    return @ticketNumbers[0] if @index >= (@count - 1)
    @ticketNumbers[@index + 1]

  prev: ->
    return @ticketNumbers[@count - 1] if @index <= 0
    @ticketNumbers[@index - 1]
