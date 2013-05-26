class StaticChart
  class Area < StaticChart
    
    
    def defaults
      super.merge(
        line_width: 0,
        axes: :right )
    end
    
    
    def line_weight
      options[:line_weight]
    end
    
    def marker_colors
      options.fetch(:marker_colors, colors)
    end
    
    
    def src
      data = self.data.reverse
      colors = self.colors.reverse
      marker_colors = self.marker_colors.reverse
      
      markers = []
      marker_colors.each_with_index do |color, i|
        markers << "B,#{color},#{i},0,0"
      end
      markers = "&chm=#{markers.join("|")}"

      chls = "&chls=" + (["#{line_weight},0,0"] * (data.length-1)).join("|") + "|0,0,0"

      min = options.fetch(:min, 0) # data.last.min
      max = options.fetch(:max, data.flatten.compact.max)
      
      src = Gchart.line(
        data: data,
        bar_colors: colors,
        bg: bg,
        axis_range: [[min, max]],
        min_value: min,
        max_value: max,
        size: size )
      
      src << markers
      src << chls
      
      case axes
      when :right
        src << "&chxt=r,x,y&chxs=0,333333,#{font_size},-1,lt|1,333333,0,0,_|2,333333,0,0,_"
      when :left
        src << "&chxt=y"
      when :bottom
        src << "&chxs=1,333333,0,0,_,333333&chxt=x,y"
      when false
        src << "&chxs=0,333333,0,0,_,333333|1,333333,0,0,_,333333&chxt=x,y"
      end
      
      src
    end
    
    
  end
end
