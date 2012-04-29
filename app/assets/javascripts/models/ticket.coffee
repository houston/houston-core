class window.Ticket extends Backbone.Model
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)


class window.Tickets extends Backbone.Collection
  model: Ticket

