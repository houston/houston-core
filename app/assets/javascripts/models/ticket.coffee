class window.Ticket extends Backbone.Model
  url: ->
    if @isNew()
      "#{App.relativeRoot()}/tickets"
    else
      "#{App.relativeRoot()}/tickets/#{@get('id')}"
  
  
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)
  
  releases: ->
    @releasesCollection ||= new Releases(@get('releases'), ticket: @)
  
  commits: ->
    @commitsCollection ||= new Commits(@get('commits'), ticket: @)
  
  activityStream: ->
    @testingNotes().models.concat(@commits().models).sortBy (item)-> item.get('createdAt')
  
  
  
  testerVerdicts: ->
    verdictsByTester = @verdictsByTester(@testingNotesSinceLastRelease())
    window.testers.map (tester)->
      email: tester.get('email')
      verdict: verdictsByTester[tester.get('id')] ? 'pending'
  
  verdict: ->
    verdicts = _.values(@verdictsByTester(@testingNotesSinceLastRelease()))
    return 'Failing' if _.include verdicts, 'failing'
    return 'Pending' if window.testers.length == 0
    
    percentOfTestersPassingTicket = verdicts.length / window.testers.length
    return 'Passing' if percentOfTestersPassingTicket >= 0.6 # If you've got at least 3/5 responses...
    'Pending'
  
  verdictsByTester: (notes)->
    verdictsByTester = {}
    notes.each (note)->
      testerId = note.get('userId')
      verdict = note.get('verdict')
      if verdict == 'fails'
        verdictsByTester[testerId] = 'failing'
      else if verdict == 'works'
        verdictsByTester[testerId] ?= 'passing'
    verdictsByTester
    
  testingNotesSinceLastRelease: ->
    date = @get('lastReleaseAt')
    if date then @testingNotes().since(date) else @testingNotes()



class window.Tickets extends Backbone.Collection
  model: Ticket
