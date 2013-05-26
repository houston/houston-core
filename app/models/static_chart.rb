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
    if options.key?(:data_by_color)
      hash = options.delete(:data_by_color)
      options.merge!(data: hash.values, colors: hash.keys)
    end
    
    @options = defaults.merge(options)
  end
  
  attr_reader :options
  
  def defaults
    { font_size: 9,
      bg: "FFFFFF00" } # transparent background
  end
  
  
  
  def width
    options[:width]
  end
  
  def height
    options[:height]
  end
  
  def retina?
    options.fetch(:retina, false)
  end
  
  def img_width
    retina? ? width * 2 : width
  end
  
  def img_height
    retina? ? height * 2 : height
  end
  
  def font_size
    retina? ? options[:font_size] * 2 : options[:font_size]
  end
  
  def size
    "#{img_width}x#{img_height}"
  end
  
  
  
  def data
    options[:data]
  end
  
  def colors
    options[:colors]
  end
  
  def labels
    options[:labels]
  end
  
  def axes
    options[:axes]
  end
  
  def title
    options[:title]
  end
  
  def bg
    options[:bg]
  end
  
  def empty?
    data.flatten.empty?
  end
  
  
  
  def src
    raise NotImplementedError
  end
  
  
  
  def to_s
    return "" if empty?
    
    src = self.src
    Rails.logger.debug "[gcharts] URL length: #{src.length} (#{title})"
    
    html = "<img src=\"#{src}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{title}\" class=\"google-chart\" />"
    html << "<h5>#{title}</h5>" if title
    html.html_safe
  end
  
end
