class StaticChart
  class Pie < StaticChart
    
    
    def to_s
      if options.key?(:data_by_color)
        hash = options[:data_by_color]
        options.merge!(data: hash.values, colors: hash.keys)
      end

      img_width   = width   = options.fetch(:width, 60)
      img_height  = height  = options.fetch(:height, width)
      if options[:retina]
        img_width *= 2
        img_height *= 2
      end

      src = Gchart.pie({
        data: options[:data],
        bar_colors: options[:colors],
        size: "#{img_width}x#{img_height}",
        labels: options[:labels],
        bg: "FFFFFF00" # transparent background
      })

      graph_with_subcaptions(src, width, height, options[:title])
    end
    
    
  end
end
