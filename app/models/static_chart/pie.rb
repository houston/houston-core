class StaticChart
  class Pie < StaticChart
    
    def defaults
      super.merge( width: 60 )
    end
    
    
    def height
      options.fetch(:height, width)
    end
    
    
    def src
      Gchart.pie(
        data: data,
        bar_colors: colors,
        size: size,
        labels: labels,
        bg: bg )
    end
    
  end
end
