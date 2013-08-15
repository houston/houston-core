class HoustonDashboard.ResponseTimeGraph extends HoustonDashboard.Graph
  # c.f. http://bost.ocks.org/mike/path/        # <-- proper animation
  #      http://bl.ocks.org/mbostock/1157787    # <-- rendering, styling
  
  
  
  constructor: (el, options)->
    super
    @graphite = new HoustonDashboard.GraphiteAdapter
      rootUrl: 'http://status.cphepdev.com/graphite/render'
      target: "stats.timers.#{@project}.response.time.mean"
  
  
  initializeGraph: ->
    super
    
    @x = d3.time.scale().range([0, @width])
    @y = d3.scale.linear().rangeRound([@height, 0])
    
    @xAxis = d3.svg.axis().scale(@x).orient('bottom').ticks(6).tickSize(0)
    @yAxis = d3.svg.axis().scale(@y).orient('right').tickFormat(d3.format(".0f")).ticks(4).tickSize(0)
    
    @area = d3.svg.area()
      .interpolate("basis")
      .x((p)=> @x(p[0]))
      .y0(@height)
      .y1((p)=> @y(p[1]))
    
    @line = d3.svg.line()
      .interpolate("basis")
      .x((p)=> @x(p[0]))
      .y((p)=> @y(p[1]))
    
    @pathArea = @svg.append("path")
      .attr("class", "area")
    
    @pathLine = @svg.append("path")
      .attr("class", "line")
    
    @axis = @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{@height})")
      .call(@xAxis)
    
    @axis2 = @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{@width},0)")
      .call(@yAxis)
  
  
  fetchStep: -> @fetchData()
  
  
  # Incremental fetches
  # fetchStep: ->
  #   @renderStep [{
  #       start: @lastTick
  #       step: @options.step
  #       stop: @lastTick + @options.step
  #       target: "summarize(stats.#{@project}.response.status.time, '30sec', 'sum')"
  #       values: [Math.random()]
  #     }]
  #   @lastTick += @options.step
  #   @observer.fire('render')
  # 
  # renderStep: (sets)->
  #   set = sets[0]
  #   
  #   value = if _.isNaN(set.values[0]) or !set.values[0] then 0 else set.values[0]
  #   @data.push [set.stop, value]
  #   
  #   @redraw(set)
  #   
  #   # pop the old data point off the front
  #   @data.shift()
  
  
  redraw: (set)->
    previousMin = @x.domain()[0] unless @firstDraw
    
    # shift domain left by 1 step so that the new point
    # is drawn off the end of the graph and slid into view
    
    # domain = @x.domain()
    # size = domain[1] - domain[0]
    # @x.domain [set.stop - size - @options.step, set.stop - @options.step]
    
    # !todo: subtract @options.step from min and max?
    extent = d3.extent(@data, (pair)-> pair[0])
    # console.log('extent:', extent)
    @x.domain extent
    
    # !todo: transition the y domain
    @y.domain [0, d3.max(@data, (pair)-> pair[1])]
    
    # redraw the line and area
    area = @svg.select(".area").data([@data])
    line = @svg.select(".line").data([@data])
    area.attr("d", @area).attr("transform", null)
    line.attr("d", @line).attr("transform", null)
    
    if @firstDraw
      @axis.call(@xAxis)
      @axis2.call(@yAxis)
      
      # area.attr("d", @area).attr("transform", null)
      # line.attr("d", @line).attr("transform", null)
      
      
    else
      
      # area.transition().duration(750).ease("linear").attr("d", @area).attr("transform", null)
      # line.transition().duration(750).ease("linear").attr("d", @line).attr("transform", null)
      
      
      shift = if previousMin then @x(previousMin) else 0
      
      @axis.transition()
        .duration(@duration)
        .ease("linear")
        .call(@xAxis)
      
      @axis2.transition()
        .duration(@duration)
        .ease("linear")
        .call(@yAxis)
      
      if previousMin
        shift = @x(previousMin)
        
        @pathLine.transition()
          .duration(@duration)
          .ease("linear")
          .attr("transform", "translate(#{shift})")
        
        @pathArea.transition()
          .duration(@duration)
          .ease("linear")
          .attr("transform", "translate(#{shift})")
  
  
  renderData: (sets)->
    set = sets[0]
    @data = []
    
    i = -1
    for timestamp in [set.start..set.stop] by set.step
      i += 1
      value = if _.isNaN(set.values[i]) or !set.values[i] then 0 else set.values[i]
      @data.push [timestamp, value]
    
    @redraw(set)
    