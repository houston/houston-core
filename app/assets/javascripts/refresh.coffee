
class window.Refresher
  
  constructor: (options) ->
    r = Raphael("timer", 42, 42)
    @R = 10
    @totalTime = options.time
    @callback = options.callback
    @refresh = 50
    
    @totalArc = 360
    @elapsedArc = 0
    
    parts = @totalTime / @refresh
    @increments = @totalArc / parts
    
    timerFill = {'stroke': "black", "stroke-width": 12}
    backgroundFill = {'stroke': "#dedede", "stroke-width": 12}
    
    r.customAttributes.arc = (value, total, R) ->
      alpha = 360 / total * value
      a = (90 - alpha) * Math.PI / 180
      x = 21 + R * Math.cos(a)
      y = 21 - R * Math.sin(a)
      
      if total == value
        path = [["M", 21, 21 - R], ["A", R, R, 0, 1, 1, 20.99, 21 - R]]
      else
        path = [["M", 21, 21 - R], ["A", R, R, 0, +(alpha > 180), 1, x, y]]
      {path: path}
    
    background = r.path().attr(backgroundFill).attr(arc: [360, 360, @R])
    sec = r.path().attr(timerFill).attr(arc: [@elapsedArc, @totalArc, @R])
    
    setInterval (=> @incArc(sec)), @refresh
  
  incArc: (sec) ->
    if Math.floor(@elapsedArc) == @totalArc
      @elapsedArc = 0
      @updateLastUpdated()
      @callback()
    sec.attr({arc: [@elapsedArc + @increments, @totalArc, @R]})
    @elapsedArc = @elapsedArc + @increments
  
  updateLastUpdated: ->
    $('#lastUpdate span').html dateFormat('shortTime')
