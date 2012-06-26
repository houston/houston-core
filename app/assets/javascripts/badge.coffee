class window.Badge
  
  constructor: ($el, n, total, status) ->
    return unless status == 'failing' or status == 'passing'
    
    $div = $('<div style="position:absolute;left:0;top:0;"></div>').appendTo($el)
    
    r = Raphael($div[0], 38, 38)
    x = y = radius = 19
    arcWidth = 360 / total
    a1 = (arcWidth * n) - 90
    a2 = a1 + arcWidth
    path = "#{App.relativeRoot()}/images/badge-#{status}.png"
    
    r.customAttributes.segment = (x, y, r, a1, a2)->
      flag = (a2 - a1) > 180
      a1 = (a1 % 360) * Math.PI / 180
      a2 = (a2 % 360) * Math.PI / 180
      {path: [["M", x, y], ["l", r * Math.cos(a1), r * Math.sin(a1)], ["A", r, r, 0, +flag, 1, x + r * Math.cos(a2), y + r * Math.sin(a2)], ["z"]]}
    
    r.path().attr
      fill: "url(#{path})"
      segment: [x, y, radius, a1, a2]
      stroke: 'none'
