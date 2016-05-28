toDate = (timestamp)->
  return timestamp if _.isDate(timestamp)
  new Date(timestamp)

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

Handlebars.registerHelper 'formatDate', (timestamp)->
  format = d3.time.format('%a %b %-d')
  format toDate(timestamp)

Handlebars.registerHelper 'formatDateWithYear', (timestamp)->
  return "" unless timestamp
  format = d3.time.format('%b %-d <span class="year">%Y</span>')
  format toDate(timestamp)

Handlebars.registerHelper 'formatDateWithYear2', (timestamp)->
  return "" unless timestamp
  format = d3.time.format('%b %-d, %Y')
  format toDate(timestamp)

Handlebars.registerHelper 'formatTime', (timestamp)->
  format = d3.time.format('%a %b %-d, %Y %-I:%M%p')
  format toDate(timestamp)
    .replace(/[AP]M/, (str)-> str.toLowerCase()[0])

Handlebars.registerHelper 'formatTimeAgo', (timestamp)->
  $.timeago toDate(timestamp)

Handlebars.registerHelper 'markdown', (markdown)-> App.mdown(markdown)

Handlebars.registerHelper 'emojify', (string)-> App.emojify(string)

Handlebars.registerHelper 'classForAge', (seconds)->
  if seconds < (6 * Duration.HOUR)
    'infant'
  else if seconds < (2 * Duration.DAY)
    'child'
  else if seconds < (7 * Duration.DAY)
    'adult'
  else if seconds < (4 * Duration.WEEK)
    'senior'
  else if seconds < (26 * Duration.WEEK)
    'old'
  else
    'ancient'

Handlebars.registerHelper 'radioButton', (object, id, name, value, selectedValue)->
  id = "#{object}_#{id}_#{name}_#{value}"
  input = "<input type=\"radio\" id=\"#{id}\" name=\"#{name}\" value=\"#{value}\""
  input = input + ' checked="checked"' if value == selectedValue
  "#{input} />"

Handlebars.registerHelper 'formatTicketSummary', (message)->
  App.formatTicketSummary(message)

Handlebars.registerHelper 'linkToCommit', (commit)->
  sha = commit.sha[0...8]
  if commit.linkTo
    "<a href=\"#{commit.linkTo}\" target=\"_blank\">#{sha}</a>"
  else
    sha

Handlebars.registerHelper 'testerAvatar', (email, size, title)->
  tester = window.testers.findByEmail(email)
  gravatarUrl = "https://www.gravatar.com/avatar/#{MD5(email.toLowerCase().trim())}?r=g&d=retro&s=#{size * 2}"
  "<img src=\"#{gravatarUrl}\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{tester.get('name')}\" />"

Handlebars.registerHelper 'userAvatar', (size)->
  user = window.user
  gravatarUrl = "https://www.gravatar.com/avatar/#{MD5(user.get('email').toLowerCase().trim())}?r=g&d=retro&s=#{size * 2}"
  "<img src=\"#{gravatarUrl}\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{user.get('name')}\" />"

Handlebars.registerHelper 'avatar', (email, size, title)->
  return "<img class=\"avatar avatar-empty\" width=\"#{size}\" height=\"#{size}\" />" unless email
  gravatarUrl = "https://www.gravatar.com/avatar/#{MD5(email.toLowerCase().trim())}?r=g&d=retro&s=#{size * 2}"
  if title
    "<img src=\"#{gravatarUrl}\" class=\"avatar\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{title}\" />"
  else
    "<img src=\"#{gravatarUrl}\" class=\"avatar\" width=\"#{size}\" height=\"#{size}\" />"

Handlebars.registerHelper 'ifEq', (v1, v2, block)->
  if v1 == v2
    block.fn(@)
  else
    block.inverse(@)

Handlebars.registerHelper 'summarizeAntecedents', (antecedents)->
  html = ''
  for kind, antecedents of _.groupBy(antecedents, (antecedent)-> antecedent.kind)
    html += "#{kind} <span class=\"badge\">#{antecedents.length}</span>"
  html

Handlebars.registerPartial 'sprintTask', (task)->
  HandlebarsTemplates['sprints/task'](task)



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

Handlebars.registerHelper 'renderTaskWorker', (task)->
  if task.checkedOutByMe and !task.historical and task.open
    '<button class="btn btn-danger check-out-button active" data-toggle="button">Check in</button>'
  else if task.checkedOutBy
    Handlebars.helpers.avatar(task.checkedOutBy.email, 24, task.checkedOutBy.firstName) +
     " #{task.checkedOutBy.firstName}"
  else if task.open
    '<button class="btn btn-info check-out-button" data-toggle="button">Check out</button>'

Handlebars.registerHelper 'renderTaskStatus', (task)->
  if task.released
    '<i class="fa fa-paper-plane"></i> Released'
  else if task.committed
    '<span class="octicon octicon-git-commit"></span> Committed'
  else if task.completed
    if task.historical then 'Completed' else '<a class="complete-task-button"></a> Completed'
  else
    if task.historical then 'Open' else '<a class="complete-task-button"></a> Open'
