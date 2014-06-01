class @TicketsView extends Backbone.View

  initialize: ->
    @tickets = @options.tickets
    @project = @options.project
    
    @$el.on 'click', 'th', (e)=>
      @toggleSort $(e.target).closest('th')
    
    @$el.on 'click', '[rel="ticket"]', (e)=>
      e.preventDefault()
      e.stopImmediatePropagation()
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
