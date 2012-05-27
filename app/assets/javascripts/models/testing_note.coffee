class window.TestingNote extends Backbone.Model
  url: ->
    if @isNew()
      "#{App.relativeRoot()}/tickets/#{@get('ticketId')}/testing_notes"
    else
      "#{App.relativeRoot()}/tickets/#{@get('ticketId')}/testing_notes/#{@get('id')}"


class window.TestingNotes extends Backbone.Collection
  model: TestingNote
  url: -> "#{App.relativeRoot()}/tickets/#{@ticket.get('id')}/testing_notes"
  
  initialize: (models, options)->
    super(models, options)
    @ticket = options.ticket
  
  since: (date)->
    @filter (note)-> note.get('createdAt') > date
