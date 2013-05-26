# This module provides view helpers for drawing pie, bar, area, and
# other kinds of graphs.
#
# Its current implementation relies on Google Image Charts which has
# been deprecated. That service will cease in April 2015.
#
# Tentatively, I plan to keep the API that this helper publishes but
# re-implement it to generate SVG charts, server-side.
#
module StaticChartHelper
  
  def pie_graph(options={})
    StaticChart::Pie.new(options)
  end
  
  def bar_graph(options={})
    StaticChart::Bar.new(options)
  end
  
  def area_graph(options={})
    StaticChart::Area.new(options)
  end
  
  
  
  # Takes a variable number of arrays
  # Expects at least one array
  # Sums the corresponding elements in each array
  def stack_sum(*arrays)
    return [] if arrays.empty?
    
    length = arrays.map(&:length).max
    
    (0...length).map do |i|
      arrays.reduce(0) { |sum, array| sum + array.fetch(i, 0) }
    end
  end
  
  # Adds each element to the sum of its predecessors
  def accumulate(array)
    cumulative = 0
    array.map do |value|
      cumulative += value
    end
  end
  
  
  
  
  def cumulative_flow_diagram(options={})
    arrivals = options[:arrivals]
    departures = options[:departures]
    colors = options[:colors]
    
    data = []
    line = stack_sum(*departures)
    data << line
    
    arrivals.each do |project_arrivals|
      line = stack_sum(line, project_arrivals)
      data << line
    end
    
    data.map!(&method(:accumulate))
    
    area_graph({
      data: data,
      width: options[:width],
      height: options[:height],
      colors: ["FFFFFF"] + colors,
      title: options[:title]
    })
  end
  
  def stacked_area_graph(options={})
    data = options[:data]
    
    length = data.map(&:length).max
    last_line = [0] * length
    
    stacked_data = data.map do |line|
      last_line = length.times.map { |i| last_line.fetch(i, 0) + line.fetch(i, 0) }
    end
    
    area_graph(options.merge(data: stacked_data))
  end
  
  
  
end
