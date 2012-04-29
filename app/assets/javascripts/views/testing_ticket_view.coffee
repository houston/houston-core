class window.TestingTicketView extends Backbone.View
  tagName: 'li'
  className: 'ticket'
  
  events:
    'submit form#new_testing_note': 'save'
  
  initialize: ->
    @ticket = @options.ticket
    @testingNotes = @ticket.testingNotes()
    @renderTicket = Handlebars.compile($('#ticket_in_testing_template').html())
    @renderNewTestingNote = Handlebars.compile($('#new_testing_note_template').html())
    @viewInEdit = null
  
  render: ->
    window.console.log '[ticket] render'
    $el = $(@el)
    json = _.extend @ticket.toJSON(),
      badgeStatus: @testingNotes.badgeStatus()
      badgeCount: @testingNotes.badgeCount()
    $el.html @renderTicket(json)
    
    # Render testing notes
    $testingNotes = $el.find('ol.testing-notes')
    @testingNotes.each (note)=>
      view = new TestingNoteView(model: note)
      view.on 'edit:begin', _.bind(@beginEditTestingNote, @)
      view.on 'edit:cancel', _.bind(@cancelEditTestingNote, @)
      view.on 'edit:commit', _.bind(@commitEditTestingNote, @)
      view.on 'destroy', _.bind(@destroyTestingNote, @)
      $testingNotes.appendView(view)
    
    # Render form for adding a testing note
    $testingNotes.append @renderNewTestingNote(ticketId: @ticket.get('id'))
    
    # Wire up the ticket in an accordian control
    $el.find('[data-toggle="collapse"]').collapse
      toggle: true
      parent: '#tickets'
    @
  
  beginEditTestingNote: (view)->
    window.console.log('beginEditTestingNote', view, @viewInEdit, @)
    @viewInEdit.commit() if @viewInEdit && @viewInEdit != view
    @viewInEdit = view
  
  cancelEditTestingNote: ->
    @viewInEdit = null
  
  commitEditTestingNote: (view, testingNote)->
    @viewInEdit = null
    @updateBadge()
  
  destroyTestingNote: (view, testingNote)->
    @testingNotes.remove(testingNote)
    $(view.el).remove()
    @updateBadge()
  
  addTestingNote: (testingNote)->  
    @testingNotes.add(testingNote)
    view = new TestingNoteView(model: testingNote)
    view.render()
    $(view.el).insertBefore($(@el).find('.testing-note.new')).highlight()
    @updateBadge()
  
  updateBadge: ->
    $(@el).find('.testing-note-badge')
      .attr('data-status', @testingNotes.badgeStatus())
      .html(@testingNotes.badgeCount())
    @
  
  save: (e)->
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
        errors = Errors.fromResponseText(response.responseText)
        errors.renderToAlert().insertBefore($(@el).find('.testing-note.new')).alert()
