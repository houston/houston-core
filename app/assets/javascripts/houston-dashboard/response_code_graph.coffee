class HoustonDashboard.ResponseCodeGraph extends HoustonDashboard.Graph
  # c.f. http://mbostock.github.io/d3/tutorial/bar-2.html     # <-- proper animation
  #      http://bost.ocks.org/mike/transition/
  
  
  constructor: (el, options)->
    super
    @countByStatusCode = {}
    @graphite = new HoustonDashboard.GraphiteAdapter
      rootUrl: 'http://status.cphepdev.com/graphite/render'
      target: "stats_counts.#{@project}.response.status.*"
  
  
  initializeGraph: ->
    super
    
    # c.f. rangeRoundBands in https://github.com/mbostock/d3/wiki/Ordinal-Scales
    @x = d3.scale.ordinal().rangeBands([0, @width], .1)
    @y = d3.scale.linear().rangeRound([@height, 0])
    
    @xt = d3.time.scale().rangeRound([0, @width])
    @xAxis = d3.svg.axis().scale(@xt).orient('bottom').ticks(6).tickSize(0)
    @yAxis = d3.svg.axis().scale(@y).orient('right').tickFormat(d3.format(".0f")).ticks(4).tickSize(0)
    
    @axis = @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{@height})")
      .call(@xAxis)
    
    @axis2 = @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{@width},0)")
      .call(@yAxis)
  
  
  fetchStep: ->
    @fetchData()
  
  
  # Incremental fetches
  # fetchStep: ->
  #     @renderStep [{
  #         start: @lastTick
  #         step: @options.step
  #         stop: @lastTick + @options.step
  #         target: "summarize(stats.#{@project}.response.status.200, '30sec', 'sum')"
  #         values: [Math.random()*2]
  #       }, {
  #         start: @lastTick
  #         step: @options.step
  #         stop: @lastTick + @options.step
  #         target: "summarize(stats.#{@project}.response.status.302, '30sec', 'sum')"
  #         values: [Math.random()]
  #       }, {
  #         start: @lastTick
  #         step: @options.step
  #         stop: @lastTick + @options.step
  #         target: "summarize(stats.#{@project}.response.status.504, '30sec', 'sum')"
  #         values: [Math.random()/2]
  #       }]
  #     @lastTick += @options.step
  #     @observer.fire('render')
  # 
  # renderStep: (sets)->
  #   data = @transformSets(sets)
  #   @data.push data[0]
  #   @data.shift()
  #   
  #   @redraw()
  
  
  redraw: ->
    @x.domain @data.map((d)-> d.timestamp)
    @xt.domain d3.extent(@data.map((d)-> d.timestamp))
    @y.domain [0, d3.max(@data, (d)-> d.total)]
    
    if @firstDraw
      @axis.call(@xAxis)
      @axis2.call(@yAxis)
    else
      @axis.transition()
        .duration(@duration)
        .ease("linear")
        .call(@xAxis)
      @axis2.transition()
        .duration(@duration)
        .ease("linear")
        .call(@yAxis)
    
    @columns = @svg.selectAll(".column")
      .data(@data, (d)-> d.timestamp)
    
    barWidth = if @firstDraw then 0 else @x(@x.domain()[1])
    @columns.enter().append("g")
        .attr("class", "column")
        .attr("transform", (d)=> "translate(#{@x(d.timestamp) + barWidth},0)")
      .transition()
        .duration(@duration)
        .attr("transform", (d)=> "translate(#{@x(d.timestamp)},0)")
    
    @columns.transition()
      .duration(@duration)
      .attr("transform", (d)=> "translate(#{@x(d.timestamp)},0)")
    
    @columns.exit().transition()
      .duration(@duration)
      .attr("transform", (d)=> "translate(#{-barWidth},0)")
      .remove()
    
    rects = @columns.selectAll("rect")
      .data(((d)-> d.values), (d)-> d.statusCode)
    
    rects.enter().append("rect")
      .attr("width", @x.rangeBand())
      .attr("y", (d)=> @y(d.y1) )
      .attr("height", (d)=> @y(d.y0) - @y(d.y1))
      .attr("class", (d)=> "status-code-#{d.statusCode}")
    
    rects
      .attr("class", (d)=> "status-code-#{d.statusCode}")
      .transition()
        .attr("width", @x.rangeBand())
        .attr("y", (d)=> @y(d.y1) )
        .attr("height", (d)=> @y(d.y0) - @y(d.y1))
  
  
  renderData: (sets)->
    @data = @transformSets(sets)
    @redraw()
  
  
  transformSets: (sets)->
    # get timestamp range from first data set
    r = sets[0]
    i = -1
    for timestamp in [r.start...r.stop] by r.step # the last step ends with stop
      i += 1
      
      y0 = 0
      entry = {timestamp: timestamp}
      
      entry.values = []
      for set in sets
        match = set.target.match(/response\.status\.(\d\d\d)\b/)
        if match # <-- one result set will be "response.status."; discard this one
          code = +match[1]
          
          entry.values.push
            statusCode: code
            y0: y0
            y1: y0 += +(set.values[i] || 0)
          
          @countByStatusCode[code] = (@countByStatusCode[code] || 0) + 1
      
      entry.total = y0
      entry



HoustonDashboard.ResponseCodeGraph.legend = [
  
  # Successful
  [200, 'OK'],
  [201, 'Created'],
  [202, 'Accepted'],
  [203, 'Non-Authoritative Information'],
  [204, 'No Content'],
  [205, 'Reset Content'],
  [206, 'Partial Content'],

  # Redirection
  [300, 'Multiple Choices'],
  [301, 'Moved Permanently'],
  [302, 'Found'],
  [303, 'See Other'],
  [304, 'Not Modified'],
  [305, 'Use Proxy'],
  [307, 'Temporary Redirect'],

  # Client Error
  [400, 'Bad Request'],
  [401, 'Unauthorized'],
  [402, 'Payment Required'],
  [403, 'Forbidden'],
  [404, 'Not Found'],
  [405, 'Method Not Allowed'],
  [406, 'Not Acceptable'],
  [407, 'Proxy Authentication Required'],
  [408, 'Request Timeout'],
  [409, 'Conflict'],
  [410, 'Gone'],
  [411, 'Length Required'],
  [412, 'Precondition Failed'],
  [413, 'Request Entity Too Large'],
  [414, 'Request-URI Too Long'],
  [415, 'Unsupported Media Type'],
  [416, 'Requested Range Not Satisfiable'],
  [417, 'Expectation Failed'],
  [422, 'Unprocessable Entity'],

  # Server Error
  [500, 'Internal Server Error'],
  [501, 'Not Implemented'],
  [502, 'Bad Gateway'],
  [503, 'Service Unavailable'],
  [504, 'Gateway Timeout'],
  [505, 'HTTP Version Not Supported']
]
