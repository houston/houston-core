class @FindOrCreateTicketView extends Backbone.View
  className: 'find-or-create-ticket'

  initialize: (options)->
    @options = options
    @template = HandlebarsTemplates['tickets/find_or_create']
    @typeaheadTemplate = HandlebarsTemplates['tickets/typeahead']
    @tickets = @options.tickets
    @addTicket = @options.addTicket
    @createTicket = @options.createTicket
    @ticketTracker = @options.ticketTracker

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

      sorter: (items)->
        view.suggestions = items
        view.$el.toggleClass('no-suggestions', items.length is 0)
        items # apply no sorting (return them in order of priority)

      highlighter: (ticket)->
        query = @query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
        regex = new RegExp("(#{query})", 'ig')
        ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
        typeaheadTemplate
          summary: ticket.summary.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          number: ticket.number.toString().replace regex, ($1, match)-> "<strong>#{match}</strong>"

    .keyup -> view.$el.toggleClass('has-content', $(@).val().length > 0)

    $add_ticket.data('typeahead').render = (tickets)->
      items = $(tickets).map (i, item)=>
        i = $(@options.item).attr('data-value', item.id)
        i.find('a').html(@highlighter(item))
        i[0]

      items.first().addClass('active')
      @$menu.html(items)
      @

    withFormFeedback = (callback)->
      $add_ticket.prop 'disabled', true
      callback()
        .success ->
          $add_ticket.prop('disabled', false).val('').focus()
        .error (response)->
          $add_ticket.prop('disabled', false).focus()
          errors = Errors.fromResponse(response)
          if errors.missingCredentials or errors.invalidCredentials
            App.promptForCredentialsTo view.ticketTracker
          else
            errors.renderToAlert()

    $add_ticket.data('typeahead').select = ->
      @hide()

      id = @$menu.find('.active').attr('data-value')
      ticket = _.detect view.tickets, (ticket)-> +ticket.id == +id
      withFormFeedback -> view.addTicket(ticket)

    @$el.find('form').submit (e)=>
      e.preventDefault()

      $add_ticket.prop 'disabled', true
      withFormFeedback => @createTicket($add_ticket.val())

    $add_ticket.focus()
