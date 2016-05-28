if $.tablesorter
  $.tablesorter.addParser
    id: 'timestamp'
    is: (s)-> false # don't auto-detect
    format: (text, table, td)-> $(td).attr('data-timestamp')
    type: 'text'

  $.tablesorter.addParser
    id: 'property'
    is: (s)-> false # don't auto-detect
    format: (text, table, td)-> +$(td).attr('data-position')
    type: 'number'

  $.tablesorter.addParser
    id: 'attr'
    is: (s)-> false # don't auto-detect
    format: (text, table, td)-> $(td).attr('data-sort-by')
    type: 'text'
