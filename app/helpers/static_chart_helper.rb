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
    if options.key?(:data_by_color)
      hash = options[:data_by_color]
      options.merge!(data: hash.values, colors: hash.keys)
    end
    
    width = options.fetch(:width, 60)
    height = options.fetch(:height, width)
    
    src = Gchart.pie({
      data: options[:data],
      bar_colors: options[:colors],
      size: "#{width}x#{height}",
      labels: options[:labels],
      bg: "FFFFFF00" # transparent background
    })
    
    graph_with_subcaptions(src, width, height, options[:title])
  end
  
  
  
  def bar_graph(options={})
    bar_width = options.fetch(:bar_width, 14)
    spacing = options.fetch(:spacing, 4)
    width = ((bar_width + spacing) * options[:count]) + 10
    axes = options.fetch(:axes, :left)
    
    width += 20 if axes == :left
    
    img_width = width
    img_height = options[:height]
    
    if options[:retina]
      bar_width *= 2
      spacing *= 2
      img_width *= 2
      img_height *= 2
    end
    
    src = Gchart.bar({
      data: options[:data],
      bar_colors: options[:colors],
      labels: options[:labels],
      bar_width_and_spacing: [bar_width, spacing],
      size: "#{img_width}x#{img_height}"
    })
    
    case axes
    when :left
      src << "&chxt=y"
    when :bottom
      src << "&chxs=1,333333,0,0,_,333333&chxt=x,y"
    when false
      src << "&chxs=0,333333,0,0,_,333333|1,333333,0,0,_,333333&chxt=x,y"
    when :label
      src << "&chxs=0,333333,0,0,_,333333|1,333333,0,0,_,333333&chxt=x,y"
    end
    
    if axes == false && Array.wrap(options[:labels]).any?
      src << "&chm=" << options[:labels].map_with_index { |label, i| "t#{label},000000,#{i},#{i},11" }.join("|")
    end
    
    graph_with_subcaptions(src, width, options[:height], options[:title])
  end
  
  
  
  def area_graph(options={})
    data = options[:data].reverse
    return "" if data.flatten.empty?
    
    colors = options[:colors].reverse
    line_weight = options.fetch(:line_weight, 0)
    marker_colors = options[:marker_colors] ? options[:marker_colors].reverse : colors
    
    markers = []
    marker_colors.each_with_index do |color, i|
      markers << "B,#{color},#{i},0,0"
    end
    markers = "&chm=#{markers.join("|")}"
    
    chls = "&chls=" + (["#{line_weight},0,0"] * (data.length-1)).join("|") + "|0,0,0"
    
    min = options.fetch(:min, 0) # data.last.min
    max = options.fetch(:max, data.flatten.compact.max)
    
    width = options[:width]
    height = options[:height]
    font_size = 11.5
    
    if options[:retina]
      width *= 2
      height *= 2
      font_size *= 1.5
    end
    
    src = Gchart.line({
      data: data,
      bar_colors: colors,
      bg: options[:bg],
      axis_range: [[min, max]],
      min_value: min,
      max_value: max,
      size: "#{width}x#{height}"
    }) + markers + chls
    
    case options.fetch(:axes, :right)
    when :right
      src << "&chxt=r,x,y&chxs=0,333333,#{font_size},-1,lt|1,333333,0,0,_|2,333333,0,0,_"
    when :left
      src << "&chxt=y"
    when :bottom
      src << "&chxs=1,333333,0,0,_,333333&chxt=x,y"
    when false
      src << "&chxs=0,333333,0,0,_,333333|1,333333,0,0,_,333333&chxt=x,y"
    end
    
    graph_with_subcaptions(src, options[:width], options[:height], options[:title])
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
  
  
  
  def graph_with_subcaptions(src, width, height, title)
    Rails.logger.debug "[gcharts] URL length: #{src.length} (#{title})"
    html = image_tag(src.html_safe, width: width, height: height, alt: title, :class => "google-chart")
    html << content_tag(:h5, title) if title
    html
  end
  
  
  
end
