class window.Ticket extends Backbone.Model
  urlRoot: '/tickets'
  
  tasks: -> @_tasks ?= new Tasks(@get('tasks'))
  estimatedEffort: ->
    effort = @tasks().reduce ((sum, task)-> sum + +task.get('effort')), 0
    if effort == 0 then null else effort
  severity: ->
    seriousness = @get('seriousness')
    likelihood = @get('likelihood')
    clumsiness = @get('clumsiness')
    return false unless seriousness && likelihood && clumsiness
    (0.6 * seriousness + 0.3 * likelihood + 0.1 * clumsiness).toFixed(1)
  
  testingNotes: ->
    @testingNotesCollection ||= new TestingNotes(@get('testingNotes'), ticket: @)
  
  releases: ->
    @releasesCollection ||= new Releases(@get('releases'), ticket: @)
  
  commits: ->
    @commitsCollection ||= new Commits(@get('commits'), ticket: @)
  
  activityStream: ->
    @testingNotes().models.concat(@commits().models).sortBy (item)-> item.get('createdAt')
  
  
  parse: (ticket)->
    ticket.openedAt = new Date(ticket.openedAt) if ticket.openedAt
    ticket.closedAt = new Date(ticket.closedAt) if ticket.closedAt
    ticket
  
  
  testerVerdicts: ->
    verdictsByTester = @verdictsByTester(@testingNotesSinceLastRelease())
    window.testers.map (tester)->
      testerId: tester.id
      email: tester.get('email')
      verdict: verdictsByTester[tester.get('id')] ? 'pending'
  
  verdict: ->
    verdicts = _.values(@verdictsByTester(@testingNotesSinceLastRelease()))
    return 'Failing' if _.include verdicts, 'failing'
    return 'Pending' if window.testers.length == 0
    
    minPassingVerdicts = @get('minPassingVerdicts') ? window.testers.length
    passingVerdicts = _.filter(verdicts, (verdict)=> verdict == 'passing').length
    return 'Passing' if passingVerdicts >= minPassingVerdicts
    
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
      else if verdict == 'badticket'
        verdictsByTester[testerId] ?= 'badticket'
      else if verdict == 'none'
        verdictsByTester[testerId] ?= 'comment'
    verdictsByTester
    
  testingNotesSinceLastRelease: ->
    date = @get('lastReleaseAt')
    if date then @testingNotes().since(date) else @testingNotes()



class window.Tickets extends Backbone.Collection
  model: Ticket
  
  search: (summary)->
    words = @getWords(summary)
    console.log(summary, '->', words)
    
    return [] if words.length == 0
    
    regexes = (new RegExp("\\b#{RegExp.escape(word)}", 'i') for word in words)
    
    results = []
    for ticket in @toJSON()
      value = _.select(regexes, (rx)-> rx.test(ticket.summary)).length
      if value > 0
        ticket.value = value
        results.push(ticket)
    results.sort(@compareTickets).slice(0, 12)
  
  compareTickets: (a, b)->
    if a.value > b.value
      -1
    else if b.value > a.value
      1
    else if a.closed && !b.closed
      1
    else if b.closed && !a.closed
      -1
    else
      0
  
  IGNORED_WORDS: ['an', 'the',
                  'if', 'when', 'then',
                  'i', 'my',
                  'and', 'or', 'but',
                  'for', 'of', 'from',
                  'should']
  
  getWords: (string)->
    words = (word.replace(/[:\|.,;!?]/, '') for word in string.split(' '))
    _.select words, (word)=>
      word.length > 1 and @IGNORED_WORDS.indexOf(word) is -1

  orderBy: (attribute, ascOrDesc)->
    tickets = @sortBy(@sorterFor(attribute))
    tickets = tickets.reverse() if ascOrDesc == 'desc'
    new @constructor(tickets)

  sorterFor: (attribute)->
    switch attribute
      when 'effort'       then (ticket)-> ticket.estimatedEffort()
      when 'severity'     then (ticket)-> ticket.severity()
      when 'seriousness'  then (ticket)-> +ticket.get('seriousness')
      when 'likelihood'   then (ticket)-> +ticket.get('likelihood')
      when 'clumsiness'   then (ticket)-> +ticket.get('clumsiness')
      when 'summary'      then (ticket)-> ticket.get('summary').toLowerCase().replace(/^\W/, '')
      when 'openedAt'     then (ticket)-> ticket.get('openedAt')
      when 'number'       then (ticket)-> ticket.get('number')
      when 'antecedents'  then (ticket)-> ticket.get('antecedents').length
      when 'closedAt'     then (ticket)-> ticket.get('closedAt')
      else throw "Tickets#sorterFor doesn't know how to sort #{attribute}!"
