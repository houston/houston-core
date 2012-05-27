class window.Ticket extends Backbone.Model
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)
  
  releases: ->
    @releasesCollection ||= new Releases(@get('releases'), ticket: @)
  
  activityStream: ->
    @testingNotes().models.concat(@releases().models).sortBy (item)-> item.get('createdAt')
  
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
  

  verdict: ->
    @testingNotes().verdict()


class window.Tickets extends Backbone.Collection
  model: Ticket
