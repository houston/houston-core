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
  
  verdictsByTester: ->
    verdictsByTester = {}
    @each (note)->
      testerId = note.get('userId')
      if note.get('verdict') == 'fails'
        verdictsByTester[testerId] = 'failing'
      else
        verdictsByTester[testerId] ?= 'passing'
    verdictsByTester
  
  verdict: ->
    verdicts = _.values(@verdictsByTester())
    if _.include verdicts, 'failing'
      'Failing'
    else if verdicts.length < window.testers.length
      'Pending'
    else
      'Passing'
