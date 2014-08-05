class Houston.BurndownChart
  
  constructor: ->
    @_margin = {top: 40, right: 80, bottom: 20, left: 50}
    @_width = 960
    @_totalEffort = 0
    @_lines = {}
  
  margin: (@_margin)-> @
  width: (@_width)-> @
  height: (@_height)-> @
  selector: (@selector)-> @ 
  days: (@days)-> @
  totalEffort: (@_totalEffort)-> @
  addLine: (slug, data)->
    @_lines[slug] = data
    @
  
  render: ->
    height = @_height || (@_width * 0.27)
    graphWidth = @_width - @_margin.left - @_margin.right
    graphHeight = height - @_margin.top - @_margin.bottom
    
    totalEffort = @_totalEffort
    unless totalEffort
      for slug, data of @_lines
        totalEffort = data[0].effort if data[0] and data[0].effort > totalEffort
    
    formatDate = d3.time.format('%A')
    
    x = d3.scale.ordinal().rangePoints([0, graphWidth], 0.75).domain(@days)
    y = d3.scale.linear().range([graphHeight, 0]).domain([0, totalEffort])
    
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat((d)=> formatDate(new Date(d)))
    
    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
    
    line = d3.svg.line()
      .interpolate('linear')
      .x((d)-> x(d.day))
      .y((d)-> y(d.effort))
    
    $(@selector).empty()
    svg = d3.select(@selector).append('svg')
        .attr('width', @_width)
        .attr('height', height)
      .append('g')
        .attr('transform', "translate(#{@_margin.left},#{@_margin.top})")
    
    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{graphHeight})")
      .call(xAxis)
    
    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)
      .append('text')
        .attr('transform', 'rotate(-90)')
        .attr('y', -45)
        .attr('x', 160 - height)
        .attr('dy', '.71em')
        .attr('class', 'legend')
        .style('text-anchor', 'end')
        .text('Points Remaining')
    
    
    
    for slug, data of @_lines
      svg.append('path')
        .attr('class', "line line-#{slug}")
        .attr('d', line(data))
      
      svg.selectAll("circle.circle-#{slug}")
        .data(data)
        .enter()
        .append('circle')
          .attr('class', "circle-#{slug}")
          .attr('r', 5)
          .attr('cx', (d)-> x(d.day))
          .attr('cy', (d)-> y(d.effort))
      
      svg.selectAll(".effort-remaining.effort-#{slug}")
        .data(data)
        .enter()
        .append('text')
          .text((d) -> d.effort)
          .attr('class', "effort-remaining effort-#{slug}")
          .attr('transform', (d)-> "translate(#{x(d.day) + 5.5}, #{y(d.effort) - 10}) rotate(-75)")
