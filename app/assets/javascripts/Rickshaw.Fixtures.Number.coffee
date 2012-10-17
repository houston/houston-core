Rickshaw.Fixtures.Number.formatDuration = (y)->
  if (y >= 3600000)         then (y / 3600000) + 'hrs'
  else if (y >= 60000)      then (y / 60000) + 'min'
  else if (y >= 1000)       then (y / 1000) + 's'
  else if (y < 1 && y > 0)  then y.toFixed(2) + 'ms'
  else if (y == 0)          then ''
  else                           y + 'ms'
