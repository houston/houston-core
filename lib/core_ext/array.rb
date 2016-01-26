module CalculatePercentiles

  # Returns the mean of all elements in array; nil if array is empty
  def mean
    return nil if self.length == 0
    self.sum / self.length
  end

  # Returns the percentile value for percentile _p_; nil if array is empty.
  #
  # _p_ should be expressed as an integer; <tt>percentile(90)</tt> returns the 90th percentile of the array.
  #
  # Algorithm from NIST[http://www.itl.nist.gov/div898/handbook/prc/section2/prc252.htm]
  # Implementation from https://github.com/bkoski/array_stats/pull/3
  def percentile(p)
    sorted_array = self.sort
    rank = (p.to_f / 100) * (self.length + 1)

    return nil if self.length == 0

    if rank.truncate > 0 && rank.truncate < self.length
      sample_0 = sorted_array[rank.truncate - 1]
      sample_1 = sorted_array[rank.truncate]

      # Returns the fractional part of a float. For example, <tt>(6.67).fractional_part == 0.67</tt>
      fractional_part =  (rank - rank.truncate).abs
      (fractional_part * (sample_1 - sample_0)) + sample_0
    elsif rank.truncate == 0
      sorted_array.first.to_f
    elsif rank.truncate == self.length
      sorted_array.last.to_f
    end
  end

end

Array.send :include, CalculatePercentiles
