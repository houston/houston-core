class @AllTicketsView extends @TicketsView
  template: HandlebarsTemplates['tickets/index']

  render: ->
    @$el.find('tbody').remove()
    
    @offset = 0
    html = @template
      tickets: (ticket.toJSON() for ticket in @tickets.slice(0, 50))
    @$el.append(html)
    @$el.find('.ticket').pseudoHover()

  showTicketModal: (number)->
    ticketNumbers: @tickets.pluck('number')
