class window.FnordMetric.ResponseTimeGauage extends window.FnordMetric.TimeseriesGauge
  
  constructor: (options={})->
    options.klass = 'ResponsetimeWidget'
    options.renderer = 'line'
    options.gauges = ['average_response_time']
    super(options)
