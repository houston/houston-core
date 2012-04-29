class window.TestingTicketsView extends Backbone.View
  el: '#tickets'
  
  initialize: ->
    @tickets = @options.tickets
    @render()
  
  render: ->
    $el = $(@el)
    $el.empty()
    @tickets.each (ticket)=>
      $el.appendView new TestingTicketView(ticket: ticket)
