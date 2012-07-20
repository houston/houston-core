Handlebars.registerHelper 'formatDuration', (seconds)->
  if seconds < Duration.HOUR
    minutes = Math.floor(seconds / Duration.MINUTE)
    unit = if minutes == 1 then 'minute' else 'minutes'
    "#{minutes} #{unit}"
  else if seconds < Duration.DAY
    hours = Math.floor(seconds / Duration.HOUR)
    unit = if hours == 1 then 'hour' else 'hours'
    "#{hours} #{unit}"
  else
    days = Math.floor(seconds / Duration.DAY)
    unit = if days == 1 then 'day' else 'days'
    "#{days} #{unit}"

Handlebars.registerHelper 'formatTime', (timestamp)->
  Date.create(timestamp).format('ddd mmm d, yyyy h:mmt')

Handlebars.registerHelper 'markdown', (markdown)->
  converter = new Markdown.Converter()
  converter.makeHtml(markdown)

# Tickets that have been in a queue for less than 2 days are 'young';
# ones that are 3-7 days old are 'adult'; tickets that have been in
# their queue longer than 7 days are 'old'.
Handlebars.registerHelper 'classForAge', (seconds)->
  # i = Math.floor(Math.random() * 3)
  # ['young', 'adult', 'old'][i]
  if seconds < (2 * Duration.DAY)
    'young'
  else if seconds < (7 * Duration.DAY)
    'adult'
  else
    'old'

Handlebars.registerHelper 'attributesForVerdict', (verdictsByTester)->
  return '' if Object.keys(verdictsByTester).length == 0
  
  attributes = ""
  for i, verdict of verdictsByTester
    attributes += " data-tester-#{i}=\"#{verdict}\""
  attributes

Handlebars.registerHelper 'radioButton', (object, id, name, value, selectedValue)->
  id = "#{object}_#{id}_#{name}_#{value}"
  input = "<input type=\"radio\" id=\"#{id}\" name=\"#{name}\" value=\"#{value}\""
  input = input + ' checked="checked"' if value == selectedValue
  "#{input} />"

Handlebars.registerHelper 'formatTicketSummary', (message)->
  [feature, sentence] = message.split(':', 2)
  if sentence then "<b>#{feature}:</b>#{sentence}" else message

Handlebars.registerHelper 'testerAvatar', (email, size, title)->
  tester = window.testers.findByEmail(email)
  gravatarUrl = "http://www.gravatar.com/avatar/#{MD5(email.toLowerCase().trim())}?r=g&d=identicon&s=#{size}"
  "<img src=\"#{gravatarUrl}\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{tester.get('name')}\" />"
  
Handlebars.registerHelper 'avatar', (email, size, title)->
  gravatarUrl = "http://www.gravatar.com/avatar/#{MD5(email.toLowerCase().trim())}?r=g&d=identicon&s=#{size}"
  "<img src=\"#{gravatarUrl}\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{title}\" />"
  
Handlebars.registerHelper 'ifEq', (v1, v2, block)->
  if v1 == v2
    block(@)
  else
    block.inverse(@)
  # if context == options.hash.compare
  #   options.fn(context)
  # else
  #   options.inverse(context)
