# ---------------------------------------
# Date Extensions
# ---------------------------------------

class window.Duration
  constructor: (@n, @units)->
  after:  (date)-> Duration.transformDateBy(date, +@n, @units)
  before: (date)-> Duration.transformDateBy(date, -@n, @units)

Duration.prototype.from = Duration.prototype.after

Duration.DAY = 86400000
Duration.WEEK = Duration.DAY * 7
Duration.transformDateBy = (date, n, units)->
  [year, month, day] = [date.getFullYear(), date.getMonth(), date.getDate()]
  switch units
    when 'days'
      new Date(year, month, (day + n))
    when 'weeks'
      new Date(year, month, (day + (n * 7)))
    when 'months'
      month = month + n
      lastDayOfMonth = new Date(year, month + 1, 0).getDate()
      new Date(year, month, Math.min(day, lastDayOfMonth))
    when 'years'
      new Date(year + n, month, day)

Number.prototype.days   = ()-> new Duration(Number(@), 'days')
Number.prototype.weeks  = ()-> new Duration(Number(@), 'weeks')
Number.prototype.months = ()-> new Duration(Number(@), 'months')
Number.prototype.years  = ()-> new Duration(Number(@), 'years')
Number.prototype.day    = Number.prototype.days
Number.prototype.week   = Number.prototype.weeks
Number.prototype.month  = Number.prototype.months
Number.prototype.year   = Number.prototype.years
