class window.TestingTicketView extends Backbone.View
  tagName: 'tr'
  className: 'ticket'
  
  events:
    'click .close-button': 'closeTicket'
    'click .reopen-button': 'reopenTicket'
    'click a.ticket-set-priority': 'setPriority'
  
  initialize: ->
    @ticket = @options.ticket
    @canClose = @options.canClose
    @testingNotes = @ticket.testingNotes()
    
    @renderTicket = HandlebarsTemplates['testing_report/ticket']
    @renderTicketDescription = HandlebarsTemplates['testing_report/description']
    @renderTesterVerdict = HandlebarsTemplates['testing_report/verdict']
    @renderNewTestingNote = HandlebarsTemplates['testing_notes/new']
    Handlebars.registerPartial 'testerVerdict', @renderTesterVerdict
    
    @numColumns = window.testers.length + 1
    @viewInEdit = null
  
  render: ->
    ticket = @ticket.toJSON()
    # window.console.log "[ticket] render ##{ticket.number}", ticket
    
    $el = $(@el)
    $el.attr 'id', "ticket_#{@ticket.id}"
    ticket.canClose = @canClose
    ticket.testerVerdicts = @ticket.testerVerdicts()
    ticket.verdict = @ticket.verdict()
    ticket.passing = ticket.verdict == 'Passing'
    ticket.failing = ticket.verdict == 'Failing'
    $el.html @renderTicket(ticket)
    
    $el.addClass("ticket-priority-#{ticket.priority}")
    $el.toggleClass('failing', ticket.failing)
    $el.toggleClass('passing', ticket.passing)
    $el.find('.close-button').toggleClass('btn-success', ticket.passing)
    @
  
  renderExpandedRow: ->
    @$testingNotes = @renderTestingNotes()
  
  renderTestingNotes: ->
    id = "ticket_#{@ticket.get('id')}_testing_notes"
    ticket = @ticket.toJSON()
    ticket.colspan = @numColumns
    $tr = $ @renderTicketDescription(ticket)
    
    @$el.after $tr
    
    $testingNotes = $tr.find('ol.testing-notes')
    
    @ticket.activityStream().each (item)=>
      if item.constructor == TestingNote
        $testingNotes.appendView @viewForTestingNote(item)
      else if item.constructor == Commit
        $testingNotes.appendView @viewForCommit(item)
    
    # Render form for adding a testing note
    if window.userId
      params =
        projectSlug: @ticket.get('projectSlug')
        ticketId: @ticket.get('id')
        tester: window.user.get('role') == 'Tester'
        developer: window.user.get('role') == 'Developer'
      $testingNotes.append @renderNewTestingNote(params)
      
      $tr.find('form#new_testing_note').submit _.bind(@createTestingNote, @)
      $tr.find('form#new_testing_note :radio[name="verdict"]').click =>
        verdict = $tr.find('form#new_testing_note :radio[name="verdict"]:checked').val() || 'none'
        $tr.find('.testing-note.new').attr('class', "testing-note new by-tester #{verdict}")
      
      $tr.find('.btn-post-and-reset').click _.bind(@createTestingNoteAndResetTicket, @)
    
    $testingNotes
  
  beginEditTestingNote: (view)->
    window.console.log('beginEditTestingNote', view, @viewInEdit, @)
    @viewInEdit.commit() if @viewInEdit && @viewInEdit != view
    @viewInEdit = view
  
  cancelEditTestingNote: ->
    @viewInEdit = null
  
  commitEditTestingNote: (view, testingNote)->
    @viewInEdit = null
    @renderTesterVerdicts()
    @trigger('testing_note:refresh')
  
  destroyTestingNote: (view, testingNote)->
    @testingNotes.remove(testingNote)
    $(view.el).remove()
    @renderTesterVerdicts()
  
  viewForTestingNote: (testingNote)->
    view = new TestingNoteView(model: testingNote)
    view.on 'edit:begin', _.bind(@beginEditTestingNote, @)
    view.on 'edit:cancel', _.bind(@cancelEditTestingNote, @)
    view.on 'edit:commit', _.bind(@commitEditTestingNote, @)
    view.on 'destroy', _.bind(@destroyTestingNote, @)
    view
  
  viewForCommit: (commit)->
    new CommitView(model: commit)
  
  addTestingNote: (testingNote)->
    @testingNotes.add(testingNote)
    
    return unless @$testingNotes
    view = @viewForTestingNote(testingNote)
    view.render()
    $(view.el).insertBefore(@$testingNotes.find('.testing-note.new')).highlight()
    @renderTesterVerdicts()
  
  renderTesterVerdicts: ->
    @render()
  
  createTestingNote: (e)->
    e.preventDefault()
    $form = $(e.target).closest('form')
    params = $form.serializeObject()
    testingNote = new TestingNote
      ticketId: @ticket.get('id')
      
    $form.disable()
    
    testingNote.save params,
      success: (model, response)=>
        $('.alert').remove()
        $form.closest('.testing-note.new').attr('class', 'testing-note new by-tester')
        $form.reset()
        @addTestingNote(testingNote)
        @trigger('testing_note:refresh')
      error: (model, response)=>
        errors = Errors.fromResponse(response)
        if errors.missingCredentials or errors.invalidCredentials
          App.promptForCredentialsTo('Unfuddle')
        errors.renderToAlert()
      complete: ->
        $form.enable()
  
  createTestingNoteAndResetTicket: (e)->
    params = {lastReleaseAt: new Date()}
    @ticket.save params,
      success: (model, response)=>
        console.log('updated lastReleaseAt', arguments)
        @render()
      error: (model, response)=>
        console.log('failed to update lastReleaseAt', arguments)
    
    @createTestingNote(e)
  
  closeTicket: (e)->
    e.preventDefault()
    $btn = $(e.target)
    
    @collapse()
    
    if $btn.hasClass('btn-success') || confirm('Are you suuuure? The ticket\'s not passing...')
      @$el.addClass('deleting')
      @$el.find('button').attr('disabled', 'disabled')
      
      @ticket.destroy
        url: "/tickets/#{@ticket.id}/close"
        wait: true
        success: (model, response)=>
          @remove()
        error: (model, response)=>
          @$el.removeClass('deleting')
          @$el.find('button').removeAttr('disabled')
          App.showErrorMessage("Unable to close ticket", response.responseText)

  reopenTicket: (e)->
    e.preventDefault()
    $btn = $(e.target)
    
    @collapse()
    
    if confirm('Are you sure you want to REOPEN this ticket?')
      @$el.addClass('deleting')
      @$el.find('button').attr('disabled', 'disabled')
      @ticket.destroy
        url: "/tickets/#{@ticket.id}/reopen"
        wait: true
        success: (model, response)=>
          @remove()
        error: (model, response)=>
          @$el.removeClass('deleting')
          @$el.find('button').removeAttr('disabled')
          App.showErrorMessage("Unable to close ticket", response.responseText)



  setPriority: (e)->
    $a = $(e.target)
    priority = $a.data('priority')
    priority = 'normal' if @$el.hasClass("ticket-priority-#{priority}")
    @$el.removeClass 'ticket-priority-low ticket-priority-normal ticket-priority-high'
    @$el.addClass "ticket-priority-#{priority}"
    @ticket.save priority: priority
