class window.Ticket extends Backbone.Model
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)
  
  testerVerdicts: ->
    verdictsByTester = @testingNotes().verdictsByTester()
    window.testers.map (tester)->
      email: tester.get('email')
      verdict: verdictsByTester[tester.get('id')] ? 'pending'
  
  getVerdictFromNotes: (notes)->
    if _.include @badgeVerdicts(), 'fails'
      'failing'
    else if @badgeVerdicts().length < @ticket.get('projectTesters').length
      'pending'
    else
      'passing'


class window.Tickets extends Backbone.Collection
  model: Ticket

