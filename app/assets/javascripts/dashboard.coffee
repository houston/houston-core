class window.Dashboard
  
  constructor: (options) ->
    @connection = new FnordMetric.Connection(options)
    
    @responseTimeGraph = new FnordMetric.ResponseTimeGauage
      connection: @connection
      id: 'response_time_graph'
      timeSpan: 120 # 2 minutes
      yAxis:
        formatter: Rickshaw.Fixtures.Number.formatDuration
    
    @statusCodeGraph = new FnordMetric.StatusCodeGauage
      connection: @connection
      id: 'status_code_graph'
      timeSpan: 120 # 2 minutes
      yAxis:
        formatter: Rickshaw.Fixtures.Number.formatKMBT
    
    @responseTimeGraph.start()
    @statusCodeGraph.start()
