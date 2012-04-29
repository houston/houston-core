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

Handlebars.registerHelper 'radioButton', (object, id, name, value, selectedValue)->
  id = "#{object}_#{id}_#{name}_#{value}"
  input = "<input type=\"radio\" id=\"#{id}\" name=\"#{name}\" value=\"#{value}\""
  input = input + ' checked="checked"' if value == selectedValue
  "#{input} />"
