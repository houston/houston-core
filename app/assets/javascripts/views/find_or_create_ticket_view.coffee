class @FindOrCreateTicketView extends Backbone.View
  
  initialize: ->
    @template = HandlebarsTemplates['tickets/find_or_create']
    @typeaheadTemplate = HandlebarsTemplates['tickets/typeahead']
    @tickets = @options.tickets
    @addTicket = @options.addTicket
  
  render: ->
    @$el.html @template()
    
    typeaheadTemplate = @typeaheadTemplate
    view = @
    $add_ticket = @$el.find('#find_or_create_ticket').attr('autocomplete', 'off').typeahead
      source: @tickets
      matcher: (item)->
        ~item.summary.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.projectTitle.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.number.toString().toLowerCase().indexOf(@query.toLowerCase())

      sorter: (items)-> items # apply no sorting (return them in order of priority)

      highlighter: (ticket)->
        query = @query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
        regex = new RegExp("(#{query})", 'ig')
        ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
        typeaheadTemplate
          summary: ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          number: ticket.number.toString().replace regex, ($1, match)-> "<strong>#{match}</strong>"

    $add_ticket.data('typeahead').render = (tickets)->
      items = $(tickets).map (i, item)=>
        i = $(@options.item).attr('data-value', item.id)
        i.find('a').html(@highlighter(item))
        i[0]

      items.first().addClass('active')
      @$menu.html(items)
      @

    addTicket = @addTicket
    $add_ticket.data('typeahead').select = ->
      id = @$menu.find('.active').attr('data-value')
      @$element.val('')
      @hide()
      addTicket(id)
