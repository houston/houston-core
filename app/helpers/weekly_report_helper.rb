module WeeklyReportHelper
  
  
  
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
      labels: options[:labels]
    }) + "&chf=bg,s,FFFFFF00"
    
    graph_with_subcaptions(src, width, height, options[:title])
  end
  
  
  
  def bar_graph(options={})
    width = ((14 + 4) * options[:count]) + 10 + 20
    
    src = Gchart.bar({
      data: options[:data],
      bar_colors: options[:colors],
      bar_width_and_spacing: 14,
      size: "#{width}x#{options[:height]}"
    }) + "&chxt=y"
    
    graph_with_subcaptions(src, width, options[:height], options[:title])
  end
  
  
  
  def area_graph(options={})
    data = options[:data].reverse
    colors = options[:colors].reverse
    line_weight = options.fetch(:line_weight, 0)
    marker_colors = options[:marker_colors] ? options[:marker_colors].reverse : colors
    
    markers = []
    marker_colors.each_with_index do |color, i|
      markers << "B,#{color},#{i},0,0"
    end
    markers = "&chm=#{markers.join("|")}"
    
    chls = "&chls=" + (["#{line_weight},0,0"] * (data.length-1)).join("|") + "|0,0,0"
    
    src = Gchart.line({
      data: data,
      bar_colors: colors,
      bg: options[:bg],
      size: "#{options[:width]}x#{options[:height]}"
    }) + markers + chls
    
    if options.fetch(:axes, true)
      src << "&chxt=r&chxs=0,676767,0,0,_,676767&chxt=y,r"
    else
      src << "&chxs=0,676767,0,0,_,676767|1,676767,0,0,_,676767&chxt=x,y"
    end
    
    graph_with_subcaptions(src, options[:width], options[:height], options[:title])
  end
  
  
  
  # Takes a variable number of arrays
  # Expects at least one array
  # Expects every array to have same length
  # Sums the corresponding elements in each array
  def accumulate(*arrays)
    (0...arrays[0].length).map do |i|
      arrays.reduce(0) { |sum, array| sum + array[i] }
    end
  end
  
  def cumulative_flow_diagram(options={})
    arrivals = options[:arrivals]
    departures = options[:departures]
    colors = options[:colors]
    
    data = []
    line = accumulate(*departures)
    data << line
    
    arrivals.each do |project_arrivals|
      line = accumulate(line, project_arrivals)
      data << line
    end
    
    data.map! do |line|
      cumulative = 0
      line.map { |value| cumulative += value }
    end
    
    area_graph({
      data: data,
      width: options[:width],
      height: options[:height],
      colors: ["FFFFFF"] + colors,
      title: options[:title],
      axes: false
    })
  end
  
  
  
  def graph_with_subcaptions(src, width, height, title)
    Rails.logger.debug "[gcharts] URL length: #{src.length} (#{title})"
    html = image_tag(src.html_safe, width: width, height: height, alt: title, :class => "google-chart")
    html << content_tag(:h5, title) if title
    html
  end
  
  
  
end
