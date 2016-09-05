class @TicketsView extends Backbone.View
  supportsSorting: true

  initialize: (options)->
    @options = options
    @tickets = @options.tickets
    @project = @options.project

    if @supportsSorting
      @$el.on 'click', 'th', (e)=>
        @toggleSort $(e.target).closest('th')

    mouseDownPosition = {}
    @$el.on 'mousedown', '[rel="ticket"]', (e)->
      mouseDownPosition = {x: e.screenX, y: e.screenY}

    @$el.on 'click', '[rel="ticket"]', (e)=>
      return if $(e.target).closest('a').length > 0

      e.preventDefault()
      e.stopImmediatePropagation()

      # If a person is trying to highlight the text
      # of this ticket, don't treat that as a click
      dx = e.screenX - mouseDownPosition.x
      dy = e.screenY - mouseDownPosition.y
      d = Math.sqrt(Math.pow(dx, 2), Math.pow(dy, 2))
      return if d > 12

      number = +$(e.target).closest('[rel="ticket"]').attr('data-number')
      App.showTicket number, @project, @showTicketModal(number)

    if @options.infiniteScroll
      new InfiniteScroll
        load: ($what)=>
          promise = new $.Deferred()
          @offset += 50
          promise.resolve @template
            tickets: (ticket.toJSON() for ticket in @tickets.slice(@offset, @offset + 50))
          promise

  renderTickets: ->
    @render()

  showTicketModal: (number)->
    {}

  toggleSort: ($th)->
    if $th.hasClass('sort-asc')
      $th.removeClass('sort-asc').addClass('sort-desc')
    else if $th.hasClass('sort-desc')
      $th.removeClass('sort-desc').addClass('sort-asc')
    else
      @$el.find('.sort-asc, .sort-desc').removeClass('sort-asc sort-desc')
      $th.addClass('sort-desc')

    attribute = $th.attr('data-attribute')
    order = if $th.hasClass('sort-desc') then 'desc' else 'asc'
    @performSort attribute, order

  performSort: (attribute, order)->
    @tickets = @tickets.orderBy(attribute, order)
    @renderTickets()
