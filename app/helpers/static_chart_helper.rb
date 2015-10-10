module StaticChartHelper

  def area_graph(options={})
    StaticChart::Area.new(options)
  end

end
