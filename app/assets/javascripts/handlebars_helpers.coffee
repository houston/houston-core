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
