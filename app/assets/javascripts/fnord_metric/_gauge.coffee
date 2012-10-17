window.FnordMetric ||= {}

class window.FnordMetric.Gauge
  
  constructor: (options={})->
    @connection = options.connection || throw "You must supply a connection"
    @klass = options.klass || throw "You must supply a klass"
    @gauges = options.gauges || throw "You must supply gauges"
    @id = options.id || throw "You must supply an element id"
    @el = $("##{@id}")
    @widgetKey = options.widgetKey ? @id
    
    @connection.observe "#{@widgetKey}.values_at", _.bind(@dataReceived, @)
  
  render: ->
    # do nothing; stub for inheritors
  
  dataReceived: (data)->
    @render()
  
  fetchData: (params={})->
    params.klass = @klass
    params.type = 'widget_request'
    params.cmd = 'values_at'
    params.gauges = @gauges
    params.widget_key = @widgetKey
    
    @connection.publish(params)
  