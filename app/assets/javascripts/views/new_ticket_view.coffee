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
  
  TYPES: ["[bug]", "[feature]", "[chore]", "[refactor]"]
  
  LABELS: [
    'Admin',
    'Global',
    'What\'s New',
    'Help',
    'Feedback',
    'Overview',
    'Overview / Upcoming Events',
    'Overview / Notifcations',
    'Overview / Data Health',
    'Overview / Recent Attendance',
    'Reports',
    'Reports / Annual Report',
    'Trends',
    'Trends / Export',
    'Trends / Print',
    'Trends Detail',
    'Trends Detail / Export',
    'Trends Detail / Print',
    'People',
    'People / Export',
    'People / Print',
    'Profile',
    'Profile / Photo',
    'Profile / General',
    'Profile / Family',
    'Profile / Attendance',
    'Profile / Offering',
    'Profile / Notes',
    'Profile / Pastoral Visits',
    'Profile / Export',
    'Mailing Labels',
    'Church Directory',
    'Add/Remove Tags',
    'Send Email',
    'Contribution Statements',
    'Households',
    'Households / Export',
    'Households / Print',
    'Household',
    'Household / Photo',
    'Household / General',
    'Household / Members',
    'Household / Notes',
    'Household / Pastoral Visits',
    'Smart Groups',
    'Tags',
    'Pastoral Visits',
    'New Person',
    'New Person / vCard',
    'Events',
    'Events / Print',
    'Event',
    'Event / Anniversary',
    'Calendars',
    'Enter Attendance',
    'Enter Offerings',
    'Enter Offerings / Export',
    'Envelopes',
    'Funds',
    'Pledges',
    'Settings',
    'Logins',
    'Permisssions',
    'Sunday School',
    'SS Import'
  ]
  
  events:
    'click #reset_ticket': 'resetNewTicket'
    'click #create_ticket': 'createNewTicket'
  
  initialize: ->
    @$el = $('#new_ticket_view')
    @project = @options.project
    @tickets = @options.tickets
    @renderSuggestion = HandlebarsTemplates['new_ticket/suggestion']
    @$suggestions = $('#ticket_suggestions')
    @$summary = $('#ticket_summary')
    @lastSearch = ''
    
    Mousetrap.bind ['ctrl+enter', 'command+enter'], (e)=>
      if $('#new_ticket_view :focus').length > 0
        @createNewTicket()
  
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
    
    $('#ticket_summary')
      .attr('autocomplete', 'off')
      .typeahead
        source: (query)->
          pos = @$element.getCursorPosition()
          a = query.indexOf(']')
          b = query.indexOf(':')
          
          if a is -1 or pos <= a
            @tquery = query.match(z)[1].toLowerCase()
            @mode = 'type'
            return view.TYPES
          
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
  
  
  
  onTicketSummaryChange: ->
    return unless @$summary.is(':focus')
    summary = @$summary.val()
    if !/\[(bug|feature|chore|refactor)\] /.test(summary)
      @$el.attr('data-mode', 'type')
      @$suggestions.empty()
    else if !/\[(bug|feature|chore|refactor)\] (.*):/.test(summary)
      @$el.attr('data-mode', 'label')
      @$suggestions.empty()
    else
      @$el.attr('data-mode', 'summary')
      md = summary.match(/\[(bug|feature|chore|refactor)\] (.*)/)
      if md
        [_, type, summary] = md
        @nextSearch = summary
        @updateSuggestions()
  
  updateSuggestions: ->
    unless @lastSearch is @nextSearch
      @lastSearch = @nextSearch
      results = @search(@nextSearch)
      list = (@renderSuggestion(ticket) for ticket in results)
      @$suggestions.empty().append list
  
  search: (summary)->
    words = @getWords(summary)
    console.log(summary, '->', words)
    
    return [] if words.length == 0
    
    regexes = (new RegExp(word, 'i') for word in words)
    
    results = []
    for ticket in @tickets
      value = _.select(regexes, (rx)-> rx.test(ticket.summary)).length
      if value > 0
        ticket.value = value
        results.push(ticket)
    results.sort(@compareTickets).slice(0, 12)
  
  compareTickets: (a, b)->
    if a.value > b.value
      -1
    else if b.value > a.value
      1
    else if a.closed && !b.closed
      1
    else if b.closed && !a.closed
      -1
    else
      0
  
  IGNORED_WORDS: ['an', 'the',
                  'and', 'or', 'but',
                  'for', 'of', 'from',
                  'should']
  
  getWords: (string)->
    words = (word.replace(/[:\|.,;!?]/, '') for word in string.split(' '))
    _.select words, (word)=>
      word.length > 1 and @IGNORED_WORDS.indexOf(word) is -1
  
  
  
  resetNewTicket: ->
    @$summary.val ''
    @$suggestions.empty()
    $('#ticket_description').val ''
    @$el.attr('data-mode', 'type')
    @hideNewTicket()
    @$summary.focus()
  
  createNewTicket: ->
    $form = $('#new_ticket_view')
    attributes = $form.serializeObject()
    
    summary = attributes['ticket[summary]']
    md = /^\s*\[(\w+)\]\s*(.*)$/.exec(summary)
    [_, type, summary] = md || [null, '', '']
    attributes['ticket[summary]'] = summary
    attributes['ticket[type]'] = type.capitalize()
    
    $form.disable()
    xhr = $.post "/projects/#{@project.slug}/tickets", attributes
    xhr.complete -> $form.enable()
    
    xhr.success (ticket)=>
      @tickets.push(ticket)
      $form.enable()
      @resetNewTicket()
    
    xhr.error (response)=>
      errors = Errors.fromResponse(response)
      if errors.missingCredentials or errors.invalidCredentials
        App.promptForCredentialsTo @project.ticketTrackerName
      else
        errors.renderToAlert().prependTo($('#body')).alert()



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
