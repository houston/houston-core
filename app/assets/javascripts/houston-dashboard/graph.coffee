@HoustonDashboard ?= {}
class HoustonDashboard.Graph
  
  
  constructor: (el, options)->
    @$el = $(el)
    @options = options
    @project = options.project
    @duration = 750
    @observer = new Observer()
    @firstDraw = true
    @initializeGraph()
  
  
  setRangeAndStep: (range, step)->
    @options.range = range
    @options.step = step
    @render()
  
  
  on: (event, callback)->
    @observer.observe(event, callback)
  
  
  render: ->
    clearInterval(@intervalId) if @intervalId
    @intervalId = setInterval _.bind(@fetchStep, @), @options.interval
    @fetchData()
  
  
  initializeGraph: ->
    margin = {top: 6, right: 40, bottom: 18, left: 0}
    @width = @options.width - margin.left - margin.right
    @height = @options.height - margin.top - margin.bottom
    
    @svg = d3.select(@$el[0])
            .append("svg")
              .attr("width", @width + margin.left + margin.right)
              .attr("height", @height + margin.top + margin.bottom)
            .append("g")
              .attr("transform", "translate(#{margin.left},#{margin.top})")
    
    @svg.append("defs").append("clipPath")
        .attr("id", "clip")
      .append("rect")
        .attr("width", @width)
        .attr("height", @height);
  
  
  fetchStep: ->
    return unless @lastTick
    # @graphite.fetch @lastTick, (@lastTick + @options.step), {step: @options.step}, (data)=>
    @graphite.fetchLast (@options.step * 2), {step: @options.step}, (data)=>
      @lastTick = data[0].stop if data.length > 0
      @renderStep(data)
      @observer.fire('render')
  
  
  fetchData: ->
    # Fetch the most recent "range",
    # letting the server determine what "now" is.
    @graphite.fetchLast @options.range, {step: @options.step}, (data)=>
      @lastTick = data[0].stop if data.length > 0
      @renderData(data)
      @firstDraw = false
      @observer.fire('render')
  
  
  renderStep: (data)->
    @renderData(data)
