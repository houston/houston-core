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
  
  
  
  def cumulative_flow_diagram(options={})
    arrivals = options[:arrivals]
    departures = options[:departures]
    colors = ["FFFFFF"] + options[:colors]
    data = []
    
    data << accumulate(stack_sum(*departures))
    
    arrivals.length.times do |i|
      project_arrivals = arrivals[i]
      project_departures = departures[i]
      
      line = project_arrivals.length.times.map { |i| project_arrivals[i] - project_departures[i] }
      data << accumulate(line)
    end
    
    area_graph(options.merge(data: data, colors: colors))
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
  
end
