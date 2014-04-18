$.tablesorter.addParser
  id: 'timestamp'
  is: (s)-> false # don't auto-detect
  format: (text, table, td)-> $(td).attr('data-timestamp')
  type: 'text'
