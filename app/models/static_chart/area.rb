class StaticChart
  class Area < StaticChart

    def defaults
      super.merge(
        line_weight: 0,
        axes: :right )
    end



    def line_weight
      options[:line_weight]
    end

    def marker_colors
      options.fetch(:marker_colors, colors)
    end

    def data
      @data ||= stack_data(super)
    end

    def min
      options.fetch(:min, 0) # data.last.min
    end

    def max
      options.fetch(:max, data.flatten.compact.max)
    end



    def src
      src = Gchart.line(
        data: data.reverse,
        bar_colors: colors.reverse,
        bg: bg,
        axis_range: [[min, max]],
        min_value: min,
        max_value: max,
        size: size )

      src << chm
      src << chls
      src << chxs
      src
    end



  protected

    def stack_data(data)
      return [] if data.empty?
      length = data.map(&:length).max
      last_line = [0] * length
      data.map { |line| last_line = length.times.map { |i| last_line.fetch(i, 0) + line.fetch(i, 0) } }
    end

    def markers
      marker_colors.reverse.each_with_index.map { |color, i| "B,#{color},#{i},0,0" }
    end

    def chls
      "&chls=" + (["#{line_weight},0,0"] * (data.length-1)).join("|") + "|0,0,0"
    end

  end
end
