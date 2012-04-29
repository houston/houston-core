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
  
  badgeVerdicts: ->
    @pluck('verdict')
  
  badgeStatus: ->
    if _.include @badgeVerdicts(), 'fails'
      'failing'
    else if @badgeVerdicts().length < @ticket.get('projectTesters').length
      'pending'
    else
      'passing'
    
  badgeCount: ->
    @length
