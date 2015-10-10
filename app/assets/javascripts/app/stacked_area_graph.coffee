class Houston.StackedAreaGraph

  constructor: ->
    @_margin = {top: 10, right: 10, bottom: 25, left: 50}
    @_width = 960
    @_height = 260
    @_data = []
    @_labels = []
    @_lines = []
    @_colors = ['rgb(31, 119, 180)', 'rgb(174, 199, 232)', 'rgb(255, 127, 14)', 'rgb(255, 187, 120)', 'rgb(44, 160, 44)']
    @_axes = ['x', 'y']

  margin: (@_margin)-> @
  width: (@_width)-> @
  height: (@_height)-> @
  selector: (@_selector)-> @
  data: (@_data)-> @
  labels: (@_labels)-> @
  colors: (@_colors)-> @
  addLine: (line)-> @_lines.push(line); @
  axes: (@_axes)-> @
  domain: (@_domain)-> @


  render: ->
    graphWidth = @_width - @_margin.left - @_margin.right
    graphHeight = @_height - @_margin.top - @_margin.bottom

    formatDate = d3.time.format('%A')

    @x = x = d3.time.scale().range([0, graphWidth])
    @y = y = d3.scale.linear().range([graphHeight, 0])

    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')

    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')

    color = d3.scale.ordinal().range(@_colors).domain(@_labels)

    area = d3.svg.area()
      .interpolate('linear')
      .x((d)-> x(d.date))
      .y0((d)-> y(d.y0))
      .y1((d)-> y(d.y0 + d.y))

    line = d3.svg.area()
      .interpolate('linear')
      .x((d)-> x(d.date))
      .y((d)-> y(d.y))

    stack = d3.layout.stack()
      .values((d)-> d.values)

    data = stack [0...@_labels.length].map (i)=>
      name: @_labels[i]
      values: @_data.map (d)->
        date: new Date(d[0])
        y: d[i + 1]

    x.domain d3.extent(data[0].values, (d)-> d.date)
    y.domain @_domain or [0, d3.max(data[@_labels.length - 1].values, (d)-> d.y + d.y0)]

    $(@_selector).empty()
    svg = d3.select(@_selector).append('svg')
        .attr('width', @_width)
        .attr('height', @_height)
      .append('g')
        .attr('transform', "translate(#{@_margin.left},#{@_margin.top})")

    if 'x' in @_axes
      svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{graphHeight})")
        .call(xAxis)

    if 'y' in @_axes
      svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)

    section = svg.selectAll('.section').data(data)

    section.enter()
      .append('g')
      .attr('class', 'section')

    section.append('path')
      .attr('class', 'area')
      .attr('d', (d)-> area(d.values))
      .style('fill', (d)-> color(d.name))

    for data in @_lines
      point.date = new Date(point.date) for point in data
      svg.append('path')
        .attr('class', 'line')
        .attr('d', line(data))
        .attr('style', 'stroke: #f00; stroke-width: 2px')

    $legend = $('<dl class="legend"></dl>').appendTo(@_selector)
    for i in [0...@_labels.length]
      label = @_labels[i]
      color = @_colors[i]
      $legend.append "<dt class=\"circle\" style=\"background: #{color}\"></dt><dd>#{label}</dd>"

    # legend = svg.append("g")
    #   .attr("class","legend")
    #   .attr("transform","translate(50,30)")
    #   .style("font-size","12px")
    #   .call(d3.legend)
