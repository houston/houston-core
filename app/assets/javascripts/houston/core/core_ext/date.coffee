Date::endOfDay = ->
  new Date(
    @getFullYear(),
    @getMonth(),
    @getDate(),
    23,
    59,
    59)
