class window.TestingTicketView extends Backbone.View
  tagName: 'li'
  className: 'ticket row-fluid'
  
  events:
    'submit form#new_testing_note': 'createTestingNote'
    'click #commit_and_reset': 'createTestingNoteAndResetTicket'
    'click .close-button': 'closeTicket'
  
  initialize: ->
    @ticket = @options.ticket
    @testingNotes = @ticket.testingNotes()
    @renderTicket = Handlebars.compile($('#ticket_in_testing_template').html())
    @renderTesterVerdict = Handlebars.compile($('#ticket_tester_verdict_template').html())
    @renderNewTestingNote = Handlebars.compile($('#new_testing_note_template').html())
    @viewInEdit = null
  
  render: ->
    # window.console.log "[ticket] render ##{@ticket.get('number')}", @ticket.toJSON()
    $el = $(@el)
    $el.html @renderTicket(@ticket.toJSON())
    
    @renderTesterVerdicts()
    @renderTestingNotes()
    
    # Wire up the ticket in an accordian control
    $el.find('[data-toggle="collapse"]')
      .collapse
        toggle: true
        parent: '#tickets'
    $el.find('.testing-notes')
      .on('show', -> $(@).closest('.ticket').addClass('expanded'))
      .on('hide', -> $(@).closest('.ticket').removeClass('expanded'))
    @
  
  renderTesterVerdicts: ->
    $el = $(@el)
    
    $testerVerdicts = $el.find('.tester-verdicts')
    $testerVerdicts.empty()
    @ticket.testerVerdicts().each (verdict)=>
      $testerVerdicts.append @renderTesterVerdict(verdict)
    
    verdict = @ticket.verdict()
    verdictHtml = verdict
    if verdict == 'Passing'
      $project = $el.closest('.project')
      maintainerIds = $project.attr('data-maintainers').split(',').map (id)-> +id
      if _.include(maintainerIds, window.userId)
        verdictHtml = '<button class="close-button btn btn-success">Close</button>'
    
    $el.find('.ticket-verdict-summary')
      .attr('class', "ticket-verdict-summary #{verdict.toLowerCase()}")
      .html(verdictHtml)
    
    @
  
  renderTestingNotes: ->
    $testingNotes = $(@el).find('ol.testing-notes')
    @ticket.activityStream().each (item)=>
      if item.constructor == TestingNote
        $testingNotes.appendView @newViewForTestingNote(item)
      else if item.constructor == Commit
        $testingNotes.appendView @newViewForCommit(item)
    
    # Render form for adding a testing note
    if window.userId
      params =
        ticketId: @ticket.get('id')
        tester: window.user.get('role') == 'Tester'
        developer: window.user.get('role') == 'Developer'
      $testingNotes.append @renderNewTestingNote(params)
    @
  
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
  
  newViewForTestingNote: (testingNote)->
    view = new TestingNoteView(model: testingNote)
    view.on 'edit:begin', _.bind(@beginEditTestingNote, @)
    view.on 'edit:cancel', _.bind(@cancelEditTestingNote, @)
    view.on 'edit:commit', _.bind(@commitEditTestingNote, @)
    view.on 'destroy', _.bind(@destroyTestingNote, @)
    view
  
  newViewForCommit: (commit)->
    new CommitView(model: commit)
  
  addTestingNote: (testingNote)->  
    @testingNotes.add(testingNote)
    view = @newViewForTestingNote(testingNote)
    view.render()
    $(view.el).insertBefore($(@el).find('.testing-note.new')).highlight()
    @renderTesterVerdicts()
  
  createTestingNote: (e)->
    e.preventDefault()
    $form = $(@el).find('form')
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
    $(@el).css(opacity: 0.2)
    $(e.target).attr('disabled', 'disabled')
    @ticket.destroy
      success: (model, response)=>
        @remove()
      error: (model, response)=>
        console.log("failed to close ticket: #{response.responseText}")
