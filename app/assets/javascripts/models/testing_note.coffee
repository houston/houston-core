class window.TestingNote extends Backbone.Model
  url: ->
    if @isNew()
      "/tickets/#{@get('ticketId')}/testing_notes"
    else
      "/tickets/#{@get('ticketId')}/testing_notes/#{@get('id')}"


class window.TestingNotes extends Backbone.Collection
  model: TestingNote
  url: -> "/tickets/#{@ticket.get('id')}/testing_notes"
  
  initialize: (models, options)->
    super(models, options)
    @ticket = options.ticket
  
  verdictsByTester: ->
    verdictsByTester = {}
    @each (note)->
      testerId = note.get('userId')
      if note.get('verdict') == 'fails'
        verdictsByTester[testerId] = 'failing'
      else
        verdictsByTester[testerId] ?= 'passing'
    verdictsByTester
