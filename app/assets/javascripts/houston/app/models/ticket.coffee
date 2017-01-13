# copied from sugar.js
escapeRegExp = (str)->
  str = String(str) unless _.isString(str)
  str.replace /([\\\/\'*+?|()\[\]{}.^$-])/g, '\\$1'


class window.Ticket extends Backbone.Model
  urlRoot: '/tickets'

  tasks: -> @_tasks ?= new Tasks(@get('tasks'))

  estimatedEffort: ->
    return @get('effort') unless _.isUndefined(@attributes.effort)
    effort = @tasks().reduce ((sum, task)-> sum + +task.get('effort')), 0
    if effort == 0 then null else effort

  estimatedEffortCompleted: ->
    effort = @tasks()
      .select (task)-> task.get('completedAt')
      .reduce ((sum, task)-> sum + +task.get('effort')), 0
    if effort == 0 then null else effort

  severity: ->
    seriousness = @get('seriousness')
    likelihood = @get('likelihood')
    clumsiness = @get('clumsiness')
    return false unless seriousness && likelihood && clumsiness
    (0.6 * seriousness + 0.3 * likelihood + 0.1 * clumsiness).toFixed(1)



  parse: (ticket)->
    ticket.openedAt = new Date(ticket.openedAt) if ticket.openedAt
    ticket.closedAt = new Date(ticket.closedAt) if ticket.closedAt
    ticket.effort = +ticket.effort if ticket.effort
    ticket



  close: ->
    url = "/projects/#{@get 'projectSlug'}/tickets/by_number/#{@get 'number'}/close"
    $.post(url).success (attributes)=> @set attributes

  reopen: ->
    url = "/projects/#{@get 'projectSlug'}/tickets/by_number/#{@get 'number'}/reopen"
    $.post(url).success (attributes)=> @set attributes




class window.Tickets extends Backbone.Collection
  model: Ticket

  search: (summary)->
    words = @getWords(summary)

    return [] if words.length == 0

    regexes = (new RegExp("\\b#{escapeRegExp(word)}", 'i') for word in words)

    results = []
    for ticket in @models
      wordsMatched = _.select(regexes, (rx)-> rx.test(ticket.get('summary'))).length
      wordsMatched += _.select(regexes, (rx)-> rx.test(ticket.get('number'))).length
      reporter = ticket.get('reporter')
      wordsMatched += _.select(regexes, (rx)-> rx.test(reporter.name)).length if reporter
      if wordsMatched > 0
        ticket.wordsMatched = wordsMatched
        results.push(ticket)
    results.sort(@compareTickets).slice(0, 12)

  compareTickets: (a, b)->
    if a.wordsMatched > b.wordsMatched
      -1
    else if b.wordsMatched > a.wordsMatched
      1
    else if a.get('closed') && !b.get('closed')
      1
    else if b.get('closed') && !a.get('closed')
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
    _.select words, (word)=> @IGNORED_WORDS.indexOf(word) is -1

  orderBy: (attribute, ascOrDesc)->
    sortBy = @sorterFor(attribute)
    [asc, desc] = if ascOrDesc == 'asc' then [1, -1] else [-1, 1]
    tickets = @models.sort (a, b)->
      [a, b] = [sortBy(a), sortBy(b)]
      aIsNull = (a is '' or !a?)
      bIsNull = (b is '' or !b?)
      return  1 if aIsNull and !bIsNull
      return -1 if bIsNull and !aIsNull
      return 0 if a == b
      if a > b then asc else desc
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
      when 'closedAt'     then (ticket)-> ticket.get('closedAt')
      else throw "Tickets#sorterFor doesn't know how to sort #{attribute}!"
