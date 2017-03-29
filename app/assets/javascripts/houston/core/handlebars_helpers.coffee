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

Handlebars.registerHelper 'userAvatar', (size)->
  user = window.user
  gravatarUrl = "https://www.gravatar.com/avatar/#{MD5(user.get('email').toLowerCase().trim())}?r=g&d=retro&s=#{size * 2}"
  "<img src=\"#{gravatarUrl}\" class=\"avatar\" width=\"#{size}\" height=\"#{size}\" rel=\"tooltip\" title=\"#{user.get('name')}\" />"

Handlebars.registerHelper 'avatar', (email, size, title)->
  return "<div class=\"avatar avatar-empty\" style=\"width:#{size}px; height:#{size}px\" />" unless email
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



Handlebars.registerHelper 'coalesce', (value, valueIfBlank)->
  value ? valueIfBlank

Handlebars.registerHelper 'ifMe', (user, block)->
  if user.id == window.user.id
    block.fn(@)
  else
    block.inverse(@)

Handlebars.registerHelper 'ifEql', (value1, value2, options)->
  if value1 == value2
    options.fn(@)

Handlebars.registerHelper 'ifIn', (value, array, options)->
  if _.contains(array, value)
    options.fn(@)

Handlebars.registerHelper 'renderKeyCombos', (keys)->
  _.map(keys, Handlebars.helpers.renderKeyCombo).join('<i> or </i>')

Handlebars.registerHelper 'renderKeyCombo', (key)->
  _.map(key.split(' '), (chord) ->
    _.map(chord.split('+'), (key) ->
      if key is "mod"
        key = if /Mac|iPod|iPhone|iPad/.test(navigator.platform) then "cmd" else "ctrl"
      "<kbd>#{inflect.capitalize key}</kbd>"
    ).join('')
  ).join('&nbsp;&nbsp;&nbsp;')
