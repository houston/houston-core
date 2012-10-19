class window.ProjectDashboard
  
  constructor: (options) ->
    @connection = new FnordMetric.Connection(options)
    
    @responseTimeGraph = new FnordMetric.ResponseTimeGauage
      application: options.project
      connection: @connection
      id: 'response_time_graph'
      timeSpan: 120 # 2 minutes
      yAxis:
        formatter: Rickshaw.Fixtures.Number.formatDuration
    
    @statusCodeGraph = new FnordMetric.StatusCodeGauage
      application: options.project
      connection: @connection
      id: 'status_code_graph'
      timeSpan: 120 # 2 minutes
      yAxis:
        formatter: Rickshaw.Fixtures.Number.formatKMBT
    
    @responseTimeGraph.start()
    @statusCodeGraph.start()
