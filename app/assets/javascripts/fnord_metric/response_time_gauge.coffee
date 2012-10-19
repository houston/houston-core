class window.FnordMetric.ResponseTimeGauage extends window.FnordMetric.TimeseriesGauge
  
  constructor: (options={})->
    options.klass = 'ResponsetimeWidget'
    options.renderer = 'area'
    options.gauges = ['average_response_time']
    @maxDataLength = options.timeSpan ? 60
    @data = []
    super(options)
  
  createSeries: (options)->
    [{ name: @widgetKey, color: 'rgba(255, 255, 255, 0.04)', stroke: 'rgba(255, 255, 255, 0.12)' }]
  
  graphOptions: (options)->
    Object.merge(super(options), {stroke: true})
  
  dataReceived: (evt)->
    @data.push(evt.data.response_time_graph)
    @data.shift() if @data.length > @maxDataLength
    super(evt)
    @setColor()
  
  setColor: ->
    maxResponseTime = @data.max()
    color = switch
      when maxResponseTime > 5000 then '244, 35, 1'   # red
      when maxResponseTime > 3000 then '229, 86, 0'   # red-orange
      when maxResponseTime > 2000 then '229, 167, 18' # orange
      when maxResponseTime > 1100 then '255, 240, 0'  # yellow
      when maxResponseTime > 500  then '146, 202, 12' # spring-green
      else                             '79, 165, 36'  # green
    
    @graph.series[0].color = "rgba(#{color}, 0.06)"
    @graph.series[0].stroke = "rgba(#{color}, 0.24)"
  