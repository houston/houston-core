class window.TestingTicketView extends Backbone.View
  tagName: 'li'
  className: 'ticket'
  
  events:
    'submit form#new_testing_note': 'createTestingNote'
  
  initialize: ->
    @ticket = @options.ticket
    @testingNotes = @ticket.testingNotes()
    @renderTicket = Handlebars.compile($('#ticket_in_testing_template').html())
    @renderTesterVerdict = Handlebars.compile($('#ticket_tester_verdict_template').html())
    @renderNewTestingNote = Handlebars.compile($('#new_testing_note_template').html())
    @viewInEdit = null
  
  render: ->
    window.console.log '[ticket] render'
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
    $testerVerdicts = $(@el).find('.tester-verdicts')
    $testerVerdicts.empty()
    @ticket.testerVerdicts().each (verdict)=>
      $testerVerdicts.append @renderTesterVerdict(verdict)
    
    verdict = @ticket.verdict()
    $(@el).find('.ticket-verdict-summary')
      .attr('class', "ticket-verdict-summary #{verdict.toLowerCase()}")
      .html(verdict)
    @
  
  renderTestingNotes: ->
    $testingNotes = $(@el).find('ol.testing-notes')
    @testingNotes.each (note)=>
      $testingNotes.appendView @newViewForTestingNote(note)
    
    # Render form for adding a testing note
    $testingNotes.append @renderNewTestingNote(ticketId: @ticket.get('id'))
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
      error: (model, response)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().insertBefore($(@el).find('.testing-note.new')).alert()
