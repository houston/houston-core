class @TicketsView extends Backbone.View
  
  initialize: ->
    @$el = $('#tickets')
    @el = @$el[0]
    @project = @options.project
    @tickets = @options.tickets
    @template = HandlebarsTemplates['tickets/index']
    @render()
    
    @$el.on 'click', 'th', (e)=> @toggleSort $(e.target).closest('th')
    
    @$el.on 'click', '[rel="ticket"]', (e)=>
      e.preventDefault()
      e.stopImmediatePropagation()
      number = +$(e.target).closest('[rel="ticket"]').attr('data-number')
      App.showTicket number, @project,
        ticketNumbers: @tickets.pluck('number')
    
    new InfiniteScroll
      load: ($what)=>
        promise = new $.Deferred()
        @offset += 50
        promise.resolve @template(tickets: (ticket.toJSON() for ticket in @tickets.slice(@offset, @offset + 50)))
        promise
  
  render: ->
    @$el.find('tbody').remove()
    
    @offset = 0
    html = @template
      tickets: (ticket.toJSON() for ticket in @tickets.slice(0, 50))
    @$el.append(html)
    @$el.find('.ticket').pseudoHover()

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
    @render()
