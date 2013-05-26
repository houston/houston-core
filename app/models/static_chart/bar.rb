class StaticChart
  class Bar < StaticChart
    
    
    def defaults
      super.merge(
        bar_width: 14,
        spacing: 4,
        axes: :left )
    end
    
    
    def bar_width
      options[:bar_width]
    end
    
    def spacing
      options[:spacing]
    end
    
    def bar_width_and_spacing
      retina? ? [bar_width * 2, spacing * 2] : [bar_width, spacing]
    end
    
    
    def width
      @width ||= begin
        w = ((bar_width + spacing) * options[:count]) + 10
        w += 20 if axes == :left
        w
      end
    end
    
    
    def src
      src = Gchart.bar(
        data: data,
        bar_colors: colors,
        labels: labels,
        bar_width_and_spacing: bar_width_and_spacing,
        size: size,
        bg: bg )
      
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
      
      src
    end
    
    
  end
end
