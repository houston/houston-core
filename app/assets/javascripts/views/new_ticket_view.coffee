class window.NewTicketView extends Backbone.View
  
  FEATURE_DESCRIPTION: '''
### Make sure that
 - 
  '''

  BUG_DESCRIPTION: '''
### Steps to Test
 - 

### What happens
 - 

### What should happen
 - 
  '''
  
  # !todo: get these from Houston.config.ticket_types
  TYPES: ['bug', 'feature', 'chore', 'enhancement']
  
  events:
    'click #reset_ticket': 'resetNewTicket'
    'click #create_ticket': 'createNewTicket'
  
  initialize: ->
    @$el = $('#new_ticket_view')
    @$el.html HandlebarsTemplates['new_ticket/form']()
    @project = @options.project
    @tickets = new Tickets(@options.tickets)
    @LABELS = @options.labels
    @TAGS = @TYPES.map (type)-> "[#{type}]"
    @TAG_MATCHER = "\\[(#{@TYPES.join('|')})\\]"
    @renderSuggestion = HandlebarsTemplates['new_ticket/suggestion']
    @$suggestions = $('#ticket_suggestions')
    @$summary = $('#ticket_summary')
    @lastSearch = ''
    
    Mousetrap.bindScoped '#ticket_summary, #ticket_description', 'mod+enter', (e)=>
      @$el.find('#create_ticket').click() if @$el.find(':focus').length > 0
  
  render: ->
    onTicketSummaryChange = _.bind(@onTicketSummaryChange, @)
    @$summary.keydown (e)=>
      if e.keyCode is 13
        e.preventDefault()
        @showNewTicket()
        $('#ticket_description').focus()
      if e.keyCode is 9
        e.preventDefault()
        @$summary.putCursorAtEnd()
    @$summary.keyup onTicketSummaryChange
    @$summary.change onTicketSummaryChange
    $('#ticket_description').focus =>
      @$el.attr('data-mode', 'description')
    
    view = @
    
    y = /\] *([^:]*)/
    z = /^([^\]]*)(\]|$)/
    
    @$summary
      .attr('autocomplete', 'off')
      .typeahead
        source: (query)->
          pos = @$element.getCursorPosition()
          a = query.indexOf(']')
          b = query.indexOf(':')
          
          if a is -1 or pos <= a
            @tquery = query.match(z)[1].toLowerCase()
            @mode = 'type'
            return view.TAGS
          
          else if a > 0 and (b is -1 or pos <= b)
            @lquery = query.match(y)[1]
            @lquery = new RegExp "\\b#{@lquery}", "i"
            @mode = 'label'
            return view.LABELS
          
          else if a > 0 and b > 0
            @mode = 'summary'
            return []
          
          else
            @mode = ''
            return []
            
        updater: (item)->
          if @mode == 'type'
            view.autocompleteDescriptionFor(item)
            @$element.val().replace(/^[^\]]*(\] ?|$)?/, item + ' ')
          else if @mode == 'label'
            @$element.val().replace(/\] ?[^:]*(: ?|$)/, '] ' + item + ': ')
            
        matcher: (item)->
          if @mode == 'type'
            ~item.toLowerCase().indexOf(@tquery)
          else if @mode == 'label'
            @lquery.test(item)
          else
            false
    
    $('#ticket_summary').focus().select()
  
  
  onTicketSummaryChange: ->
    return unless @$summary.is(':focus')
    summary = @$summary.val()
    if !///#{@TAG_MATCHER} ///.test(summary)
      @$el.attr('data-mode', 'type')
      @$suggestions.empty()
    else if !///#{@TAG_MATCHER} (.*):///.test(summary)
      @$el.attr('data-mode', 'label')
      @$suggestions.empty()
    else
      @$el.attr('data-mode', 'summary')
      md = summary.match(///#{@TAG_MATCHER} (.*)///)
      if md
        [_, type, summary] = md
        @nextSearch = summary
        @updateSuggestions()
  
  updateSuggestions: ->
    unless @lastSearch is @nextSearch
      @lastSearch = @nextSearch
      results = @tickets.search(@nextSearch)
      list = (@renderSuggestion(ticket) for ticket in results)
      @$suggestions.empty().append list
  

  
  
  
  resetNewTicket: (e)->
    e?.preventDefault()
    @$summary.val ''
    @$suggestions.empty()
    $('#ticket_description').val ''
    @$el.attr('data-mode', 'type')
    @hideNewTicket()
    @$summary.focus()
  
  createNewTicket: ->
    attributes = @$el.serializeObject()
    
    @$el.disable()
    
    xhr = $.post "/projects/#{@project.slug}/tickets", attributes
    xhr.complete => @$el.enable()
    
    xhr.success (ticket)=>
      @tickets.push(ticket)
      @resetNewTicket()
      $("<div class=\"alert alert-success\">Ticket <a href=\"#{ticket.ticketUrl}\" target=\"_blank\">##{ticket.number}</a> was created.</div>").appendAsAlert()
      @$el.enable()
      $(document).trigger 'ticket:create', [ticket]
    
    xhr.error (response)=>
      errors = Errors.fromResponse(response)
      if errors.missingCredentials or errors.invalidCredentials
        App.promptForCredentialsTo @project.ticketTrackerName
      else if errors.oauthLocation
        App.oauth(errors.oauthLocation)
      else
        errors.renderToAlert().appendAsAlert()



  showNewTicket: ->
    $('#ticket_suggestions').hide()
    $('.sequence-new-ticket-full').slideDown 200, ->
      $('#ticket_description').autosize()

  hideNewTicket: ->
    $('.sequence-new-ticket-full').slideUp 200, ->
      $('#ticket_suggestions').show()



  autocompleteDescriptionFor: (type)->
    $('#ticket_description')
      .val(@defaultDescriptionFor(type))
      .trigger('autosize.resize')

  defaultDescriptionFor: (type)->
    switch type
      when '[feature]' then @FEATURE_DESCRIPTION
      when '[bug]' then @BUG_DESCRIPTION
      else ''
