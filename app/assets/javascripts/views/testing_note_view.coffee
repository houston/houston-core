class window.TestingNoteView extends Backbone.View
  tagName: 'li'
  className: 'testing-note'
  
  events:
    'click .edit-note': 'edit'
    'click .destroy-note': 'destroy'
    'click .btn-cancel': 'cancel'
  
  initialize: ->
    @isInEditMode = false
    @renderTestingNote = Handlebars.compile($('#testing_note_template').html())
    @renderEditTestingNote = Handlebars.compile($('#edit_testing_note_template').html())
    $(@el).delegate 'form', 'submit', _.bind(@commit, @)
  
  render: ->
    $el = $(@el)
    renderer = if @isInEditMode then @renderEditTestingNote else @renderTestingNote
    $el.html renderer(_.extend(@model.toJSON(), {editable: @isEditable()}))
    $el.attr('class', "testing-note #{@model.get('verdict')}")
    @
  
  isEditable: ->
    @model.get('userId') == window.userId
  
  edit: ->
    if @isEditable() and !@isInEditMode
      @isInEditMode = true
      @render()
      @trigger('edit:begin', @)
    @
  
  commit: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    if @isInEditMode
      $form = $(@el).find('form')
      params = $form.serializeObject()
      previousAttributes = @model.previousAttributes()
      @model.save params,
        success: (model, response)=>
          @isInEditMode = false
          @render()
          @trigger('edit:commit', @, @model)
        error: (model, response)=>
          @model.set(previousAttributes, {silent: true})
          errors = Errors.fromResponseText(response.responseText)
          errors.renderToAlert().prependTo($(@el)).alert()
    @
  
  cancel: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    if @isInEditMode
      @isInEditMode = false
      @render()
      @trigger('edit:cancel', @)
    @
  
  destroy: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    @model.destroy
      success: =>
        @trigger('destroy', @, @model)
    @
