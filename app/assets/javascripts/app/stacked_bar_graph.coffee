class Houston.StackedBarGraph

  constructor: ->
    @_margin = {top: 0, right: 80, bottom: 40, left: 50}
    @_width = 960
    @_height = 260
    @_data = []
    @_legend = true
    @_labels = []
    @_colors = ['rgb(31, 119, 180)', 'rgb(174, 199, 232)', 'rgb(255, 127, 14)', 'rgb(255, 187, 120)', 'rgb(44, 160, 44)']
    @_axes = ['x', 'y']

  legend: (@_legend)-> @
  margin: (@_margin)-> @
  width: (@_width)-> @
  height: (@_height)-> @
  selector: (@_selector)-> @
  data: (@_data)-> @
  labels: (@_labels)-> @
  colors: (@_colors)-> @
  range: (@_range)-> @
  axes: (@_axes)-> @
  yTicks: (@_yTicks)-> @

  render: ->
    graphWidth = @_width - @_margin.left - @_margin.right
    graphHeight = @_height - @_margin.top - @_margin.bottom

    formatDate = d3.time.format('%A')

    x = d3.scale.ordinal().rangeRoundBands([0, graphWidth], 0.15)
    y = d3.scale.linear().range([graphHeight, 0])

    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat(d3.time.format('%b %-d'))

    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
    yAxis.tickValues(@_yTicks) if @_yTicks

    color = d3.scale.ordinal().range(@_colors).domain(@_labels)

    stack = d3.layout.stack()
      .values((d)-> d.values)

    data = stack [0...@_labels.length].map (i)=>
      name: @_labels[i]
      values: @_data.map (d)=>
        name: @_labels[i]
        date: new Date(d[0])
        y: d[i + 1] ? 0

    x.domain _.map(data[0].values, (d)-> d.date)
    max = d3.max(data[@_labels.length - 1].values, (d)-> d.y + d.y0)
    max = d3.max([max, @_range[1]]) if @_range
    y.domain [0, max]

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

    section = svg.selectAll('.section')
      .data(x.domain())

    section.enter()
      .append('g')
      .attr('class', 'section')
      .attr('transform', (date)-> "translate(#{x(date)},0)")

    section.selectAll('rect')
        .data (date, i)->
          for bar in data
            name: bar.name
            y1: bar.values[i].y0 + bar.values[i].y
            y0: bar.values[i].y0
      .enter()
        .append('rect')
        .attr('class', 'bar')
        .attr('width', x.rangeBand())
        .attr('y', (d)-> y(d.y1))
        .attr('height', (d)-> y(d.y0) - y(d.y1))
        .style('fill', (d)-> color(d.name))

    if @_legend
      $legend = $('<dl class="legend"></dl>').appendTo(@_selector)
      for i in [0...@_labels.length]
        label = @_labels[i]
        color = @_colors[i]
        $legend.append "<dt class=\"circle\" style=\"background: #{color}\"></dt><dd>#{label}</dd>"

    @
