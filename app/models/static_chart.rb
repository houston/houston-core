# This class provides view helpers for drawing pie, bar, area, and
# other kinds of graphs.
#
# Its current implementation relies on Google Image Charts which has
# been deprecated. That service will cease in April 2015.
#
# Tentatively, I plan to keep the API that this helper publishes but
# re-implement it to generate SVG charts, server-side.
#
class StaticChart
  
  def initialize(options={})
    @options = options
  end
  
  attr_reader :options
  
  
  
  def graph_with_subcaptions(src, width, height, title)
    Rails.logger.debug "[gcharts] URL length: #{src.length} (#{title})"
    html = "<img src=\"#{src}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{title}\" class=\"google-chart\" />"
    html << "<h5>#{title}</h5>" if title
    html.html_safe
  end
  
end
