class window.Duration
  constructor: (@n, @units)->
  after:  (date)-> Duration.transformDateBy(date, +@n, @units)
  before: (date)-> Duration.transformDateBy(date, -@n, @units)

Duration::from = Duration::after

Duration.MINUTE = 60
Duration.HOUR = Duration.MINUTE * 60
Duration.DAY = Duration.HOUR * 24
Duration.WEEK = Duration.DAY * 7
Duration.transformDateBy = (date, n, units)->
  switch units
    when 'minutes' then new Date(date.getTime() + (n * Duration.MINUTE))
    when 'hours' then new Date(date.getTime() + (n * Duration.HOUR))
    when 'days' then new Date(date.getTime() + (n * Duration.DAY))
    when 'weeks' then new Date(date.getTime() + (n * Duration.WEEK))
    when 'months'
      [year, month, day] = [date.getFullYear(), date.getMonth() + n, date.getDate()]
      lastDayOfMonth = new Date(year, month + 1, 0).getDate()
      new Date(year, month, Math.min(day, lastDayOfMonth))
    when 'years'
      [year, month, day] = [date.getFullYear() + n, date.getMonth(), date.getDate()]
      new Date(year, month, day)

Number::minutes  = ()-> new Duration(Number(@), 'minutes')
Number::hours    = ()-> new Duration(Number(@), 'hours')
Number::days     = ()-> new Duration(Number(@), 'days')
Number::weeks    = ()-> new Duration(Number(@), 'weeks')
Number::months   = ()-> new Duration(Number(@), 'months')
Number::years    = ()-> new Duration(Number(@), 'years')
Number::minutes  = Number::minutes
Number::hours    = Number::hours
Number::day      = Number::days
Number::week     = Number::weeks
Number::month    = Number::months
Number::year     = Number::years
