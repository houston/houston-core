@HoustonDashboard ?= {}
class HoustonDashboard.GraphiteAdapter
  
  constructor: (options)->
    @targets = options.targets ? [options.target]
    @rootUrl = options.rootUrl
  
  
  fetch: (startTime, endTime, options={}, callback)->
    console.log "fetching #{@formatRequestUrl(startTime, endTime, options)}"
    $.get @formatRequestUrl(startTime, endTime, options), (raw)=> 
      callback(@parseResponse(raw))
  
  fetchLast: (range, options={}, callback)->
    console.log "fetching #{@formatRequestRangeUrl(range, options)}"
    $.get @formatRequestRangeUrl(range, options), (raw)=> 
      callback(@parseResponse(raw))
  
  formatRequestUrl: (startTime, endTime, options={})->
    parameters = @formatTargets(options).concat [
      'format=raw'
      "from=#{@formatTime(startTime)}"
      "until=#{@formatTime(endTime)}"
    ]
    "#{@rootUrl}?#{parameters.join("&")}"
  
  formatRequestRangeUrl: (range, options={})->
    parameters = @formatTargets(options).concat [
      'format=raw'
      "from=-#{@formatRelativeTime(range)}"
    ]
    "#{@rootUrl}?#{parameters.join("&")}"
  
  formatTargets: (options={})->
    step = @formatStep(options.step) if options.step
    @targets.map (target)->
      target = "summarize(#{target},'#{step}','sum')" if step
      target = "sum(#{target})" if options.sum
      "target=#{target}"
  
  formatStep: (step)->
    return "#{step / 864e5}day"  if step % 864e5 is 0
    return "#{step /  36e5}hour" if step %  36e5 is 0
    return "#{step /   6e4}min"  if step %   6e4 is 0
    "#{step / 1e3}sec"
  
  formatRelativeTime: (range)->
    return "#{range / 864e5}d"   if range % 864e5 is 0
    return "#{range /  36e5}h"   if range %  36e5 is 0
    return "#{range /   6e4}min" if range %   6e4 is 0
    "#{range / 1e3}s"
  
  formatTime: (time)->
    Math.floor(time / 1000) # Graphite understands seconds since UNIX epoch.
  
  parseResponse: (raw)->
    raw.split('\n').map (line)=> @parseLine(line)
  
  parseLine: (raw)->
    i = raw.indexOf("|")
    meta = raw.substring(0, i)
    c = meta.lastIndexOf(",")
    b = meta.lastIndexOf(",", c - 1)
    a = meta.lastIndexOf(",", b - 1)
    target = meta.substring(0, a)
    start = meta.substring(a + 1, b) * 1000
    stop = meta.substring(b + 1, c) * 1000
    step = meta.substring(c + 1) * 1000
    
    target: target
    start: start
    stop: stop
    step: step
    values: raw.substring(i + 1).split(',').slice(1).map (value)-> +value
