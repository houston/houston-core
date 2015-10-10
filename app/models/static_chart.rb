# This class provides view helpers for drawing pie, bar, area, and
# other kinds of graphs.
#
# Its current implementation relies on Google Image Charts which has
# been deprecated. That service will cease in April 2015.
#
# Tentatively, I plan to keep the API that this helper publishes but
# re-implement it to generate SVG charts, server-side.
#
# Google limits charts to 300000 pixels
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

  def render_graph
    src = self.src
    Rails.logger.debug "[gcharts] URL length: #{src.length} (#{title})"
    "<img src=\"#{src}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{title}\" class=\"google-chart\" />"
  end

  def to_s
    return "" if empty?

    html = render_graph
    html << "<h5>#{title}</h5>" if title
    html.html_safe
  end



protected

  def chm
    markers = self.markers
    return "" if markers.empty?
    "&chm=#{markers.join("|")}"
  end

  def markers
    []
  end

  def chxs
    case axes
    when :right
      "&chxt=r,x,y&chxs=0,333333,#{font_size},-1,lt|1,333333,0,0,_|2,333333,0,0,_"
    when :left
      "&chxt=y&chxs=0,333333,#{font_size},-1,lt"
    when :bottom
      "&chxs=1,333333,0,0,_,333333&chxt=x,y"
    when false, :label
      "&chxs=0,333333,0,0,_,333333|1,333333,0,0,_,333333&chxt=x,y"
    end
  end

end
