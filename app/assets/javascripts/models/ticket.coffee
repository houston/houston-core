class window.Ticket extends Backbone.Model
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)
  
  releases: ->
    @releasesCollection ||= new Releases(@get('releases'), ticket: @)
  
  activityStream: ->
    @testingNotes().models.concat(@releases().models).sortBy (item)-> item.get('createdAt')
  
  
  
  testerVerdicts: ->
    verdictsByTester = @verdictsByTester(@testingNotesSinceLastRelease())
    window.testers.map (tester)->
      email: tester.get('email')
      verdict: verdictsByTester[tester.get('id')] ? 'pending'
  
  verdict: ->
    verdicts = _.values(@verdictsByTester(@testingNotesSinceLastRelease()))
    if _.include verdicts, 'failing'
      'Failing'
    else if verdicts.length < window.testers.length
      'Pending'
    else
      'Passing'
  
  verdictsByTester: (notes)->
    verdictsByTester = {}
    notes.each (note)->
      testerId = note.get('userId')
      if note.get('verdict') == 'fails'
        verdictsByTester[testerId] = 'failing'
      else
        verdictsByTester[testerId] ?= 'passing'
    verdictsByTester
    
  testingNotesSinceLastRelease: ->
    date = @get('lastReleaseAt')
    if date then @testingNotes().since(date) else @testingNotes()



class window.Tickets extends Backbone.Collection
  model: Ticket
