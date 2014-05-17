class @TicketsView extends Backbone.View
  # !todo: finish view
  
  initialize: ->
    @$el = $('#tickets')
    @el = @$el[0]
    @tickets = for ticket in @options.tickets
      ticket.openedAt = new Date(ticket.openedAt)
      ticket.closedAt = new Date(ticket.closedAt) if ticket.closedAt
      ticket
    @template = HandlebarsTemplates['tickets/index']
    @render()
    
    @$el.on 'click', 'th', (e)=> @toggleSort $(e.target).closest('th')
    
    new InfiniteScroll
      load: ($what)=>
        promise = new $.Deferred()
        @offset += 50
        promise.resolve @template(tickets: @tickets.slice(@offset, @offset + 50))
        promise
  
  render: ->
    @$el.find('tbody').remove()
    
    @offset = 0
    html = @template(tickets: @tickets.slice(0, 50))
    @$el.append(html)

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
    sorter = @["#{attribute}Sorter"]
    return console.log "#{attribute}Sorter is undefined!" unless sorter
    
    @tickets = @tickets.sortBy(sorter)
    @tickets = @tickets.reverse() if order == 'desc'
    @render()

  numberSorter: (ticket)-> ticket.number
  summarySorter: (ticket)-> ticket.summary.toLowerCase().replace(/^\W/, '')
  antecedentsSorter: (ticket)-> ticket.antecedents.length
  openedAtSorter: (ticket)-> ticket.openedAt
  closedAtSorter: (ticket)-> ticket.closedAt
