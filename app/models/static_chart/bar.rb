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
      
      src << chxs
      src << chm
      src
    end
    
    
    
  protected
    
    def markers
      return [] unless axes == false && Array.wrap(options[:labels]).any?
      options[:labels].map_with_index { |label, i| "t#{label},000000,#{i},#{i},11" }
    end
    
  end
end
