class Houston.BurndownChart

  constructor: ->
    @_margin = {top: 40, right: 0, bottom: 24, left: 50}
    @_selector = '#graph'
    @_height = 260
    @$el = $(@_selector)
    @_totalEffort = 0
    @_lines = {}
    @_regressions = {}
    $(window).resize (e)=>
      @render() if e.target is window

  margin: (@_margin)-> @
  height: (@_height)-> @
  selector: (@_selector)-> @$el = $(@_selector); @
  dateFormat: (@_dateFormat)-> @
  days: (@days)-> @
  totalEffort: (@_totalEffort)-> @
  addLine: (slug, data)-> @_lines[slug] = data; @
  addRegression: (slug, data)-> @_regressions[slug] = data; @

  render: ->
    width = @$el.width() || 960
    height = @_height
    graphWidth = width - @_margin.left - @_margin.right
    graphHeight = height - @_margin.top - @_margin.bottom

    totalEffort = @_totalEffort
    unless totalEffort
      for slug, data of @_lines
        totalEffort = data[0].effort if data[0] and data[0].effort > totalEffort

    formatDate = @_dateFormat || d3.time.format('%A')

    [min, max] = d3.extent(@days)
    x = d3.scale.ordinal().rangePoints([0, graphWidth], 0.75).domain(@days)
    y = d3.scale.linear().range([graphHeight, 0]).domain([0, totalEffort])
    rx = d3.scale.linear().range([x(min), x(max)]).domain([min, max])

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

    @$el.empty()
    svg = d3.select(@_selector).append('svg')
        .attr('width', width)
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



    for slug, data of @_regressions
      svg.append('line')
        .attr('class', "regression regression-#{slug}")
        .attr('x1', rx(data.x1))
        .attr('y1', y(data.y1))
        .attr('x2', rx(data.x2))
        .attr('y2', y(data.y2))



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
