class window.FnordMetric.StatusCodeGauage extends window.FnordMetric.TimeseriesGauge
  
  constructor: (options={})->
    options.klass = 'ResponsestatusWidget'
    options.renderer = 'bar'
    options.gauges = ['responses_by_status_code']
    super(options)
  
  createSeries: (options)->
    palette = new Rickshaw.Color.Palette({ scheme: 'httpStatus' })
    for statusCode, color of palette.scheme
      {name: statusCode, color: color}
