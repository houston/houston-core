class window.TestingTicketView extends Backbone.View
  tagName: 'tr'
  className: 'ticket'
  
  events:
    'click': 'showOrHideTestingNotes'
    'click .close-button': 'closeTicket'
  
  initialize: ->
    @ticket = @options.ticket
    @testingNotes = @ticket.testingNotes()
    
    @renderTicket = HandlebarsTemplates['testing_report/ticket']
    @renderTicketDescription = HandlebarsTemplates['testing_report/description']
    @renderTesterVerdict = HandlebarsTemplates['testing_report/verdict']
    @renderNewTestingNote = HandlebarsTemplates['testing_notes/new']
    Handlebars.registerPartial 'testerVerdict', @renderTesterVerdict
    
    @numColumns = window.testers.length
    @viewInEdit = null
  
  render: ->
    ticket = @ticket.toJSON()
    # window.console.log "[ticket] render ##{ticket.number}", ticket
    
    $el = $(@el)
    ticket.maintainer = _.include(ticket.projectMaintainers, window.userId)
    ticket.testerVerdicts = @ticket.testerVerdicts()
    ticket.verdict = @ticket.verdict()
    ticket.passing = ticket.verdict == 'Passing'
    ticket.failing = ticket.verdict == 'Failing'
    $el.html @renderTicket(ticket)
    
    $el.toggleClass('failing', ticket.failing)
    $el.toggleClass('passing', ticket.passing)
    $el.find('.close-button').toggleClass('btn-success', ticket.passing)
    @
  
  showOrHideTestingNotes: (e)->
    return if @$el.hasClass('in-transition')
    return if $(e.target).is('button, a, input')
    
    if @$el.hasClass('expanded')
      @collapse()
    else
      @expand()
      
  expand: ->
    @trigger('expanding')
    @$el.addClass('expanded in-transition')
    @$testingNotes = @renderTestingNotes()
    @$testingNotes.slideDown =>
      @$el.removeClass('in-transition')
      @trigger('expanded')
  
  collapse: (speed)->
    return unless @$testingNotes
    
    finish = =>
      @$el.removeClass('expanded in-transition')
      @$testingNotes.closest('tr').remove()
      @$testingNotes = null
    
    if speed == 'fast'
      finish()
    else
      @$el.addClass('in-transition')
      @$testingNotes.slideUp(finish)
  
  renderTestingNotes: ->
    id = "ticket_#{@ticket.get('id')}_testing_notes"
    $tr = $ @renderTicketDescription(@ticket.toJSON())
    $tr.find('.white-space').attr('colspan', @numColumns)
    
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
        ticketId: @ticket.get('id')
        tester: window.user.get('role') == 'Tester'
        developer: window.user.get('role') == 'Developer'
      $testingNotes.append @renderNewTestingNote(params)
      
      $tr.find('form#new_testing_note').submit _.bind(@createTestingNote, @)
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
    testingNote.save params,
      success: (model, response)=>
        $('.alert').remove()
        $form.reset()
        @addTestingNote(testingNote)
        @trigger('testing_note:refresh')
      error: (model, response)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().insertBefore($(@el).find('.testing-note.new')).alert()
  
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
    
    if $btn.hasClass('btn-success') || confirm('Are you suuuure? The ticket\'s not passing...')
      $(@el).css(opacity: 0.2)
      $btn.attr('disabled', 'disabled')
      @ticket.destroy
        success: (model, response)=>
          @remove()
        error: (model, response)=>
          console.log("failed to close ticket: #{response.responseText}")
