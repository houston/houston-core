class window.Duration
  constructor: (@n, @units)->
  after:  (date)-> date && Duration.transformDateBy(date, +@n, @units)
  before: (date)-> date && Duration.transformDateBy(date, -@n, @units)
  ago: -> @before(new Date())
  fromNow: -> @after(new Date())
  valueOf: ->
    switch @units
      when 'seconds' then @n * Duration.SECOND
      when 'minutes' then @n * Duration.MINUTE
      when 'hours' then @n * Duration.HOUR
      when 'days' then @n * Duration.DAY
      when 'weeks' then @n * Duration.WEEK
      when 'months' then @n * Duration.AVGMONTH
      when 'years' then @n * Duration.AVGYEAR

Duration::from = Duration::after

Duration.SECOND = 1000
Duration.MINUTE = 60000
Duration.HOUR = Duration.MINUTE * 60
Duration.DAY = Duration.HOUR * 24
Duration.WEEK = Duration.DAY * 7
Duration.AVGMONTH = Duration.WEEK * 4.3452380952381
Duration.AVGYEAR = Duration.DAY * 365
Duration.transformDateBy = (date, n, units)->
  [year, month, day] = [date.getFullYear(), date.getMonth(), date.getDate()]
  switch units
    when 'seconds' then new Date(date.getTime() + (n * Duration.SECOND))
    when 'minutes' then new Date(date.getTime() + (n * Duration.MINUTE))
    when 'hours' then new Date(date.getTime() + (n * Duration.HOUR))
    when 'days' then new Date(year, month, (day + n))
    when 'weeks' then new Date(year, month, (day + (n * 7)))
    when 'months'
      month = month + n
      lastDayOfMonth = new Date(year, month + 1, 0).getDate()
      new Date(year, month, Math.min(day, lastDayOfMonth))
    when 'years' then new Date(year + n, month, day)

Number::seconds  = ()-> new Duration(Number(@), 'seconds')
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
