class StaticChart
  class Bar < StaticChart
    
    
    def to_s
      bar_width   = options.fetch(:bar_width, 14)
      spacing     = options.fetch(:spacing, 4)
      width       = ((bar_width + spacing) * options[:count]) + 10
      axes        = options.fetch(:axes, :left)
      width += 20 if axes == :left
      img_width   = width
      img_height  = height = options[:height]

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

      graph_with_subcaptions(src, width, height, options[:title])
    end
    
    
  end
end
