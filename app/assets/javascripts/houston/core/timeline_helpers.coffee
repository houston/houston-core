toDate = (timestamp)->
  return timestamp if _.isDate(timestamp)
  new Date(timestamp)

Handlebars.registerHelper 'timelineDateRange', (lastDate, date)->
  return Handlebars.helpers.timelineDate(date) unless lastDate
  days = (lastDate - date) / Duration.DAY
  return Handlebars.helpers.timelineDateAfterGap(date) if days >= 3

  _.inject [0...days],
    ((html, i)-> html + Handlebars.helpers.timelineDate((i + 1).days().before(lastDate)))
  , ''

Handlebars.registerHelper 'timelineDate', (date)->
  format = d3.time.format """
  <div class="timeline-date">
    <span class="weekday">%a</span>
    <span class="month">%b</span>
    <span class="day">%-d</span>
    <span class="year">%Y</span>
  </div>
  """
  format toDate(date)

Handlebars.registerHelper 'timelineTime', (time)->
  format = d3.time.format('<span class="timeline-event-time">%-I:%M%p</span>')
  format toDate(time)
    .replace(/[AP]M/, (str)-> str.toLowerCase()[0])

Handlebars.registerHelper 'timelineDateAfterGap', (date)->
  '<div class="timeline-date-gap"></div>' + Handlebars.helpers.timelineDate(date)

Handlebars.registerHelper 'timeline', (events, options)->
  lastDate = null
  events ?= []
  if events.length > 0
    html = '<div class="timeline">'
    for event in events
      date = App.truncateDate(toDate(event.date || event.time))
      html += Handlebars.helpers.timelineDateRange(lastDate, date)
      html += options.fn(event)
      lastDate = date
    html += '</div>'
  html
