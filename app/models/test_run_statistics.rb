class TestRunStatistics

  def initialize(project)
    @project = project
  end

  attr_reader :project

  def last_completed_test_runs(n)
    project.test_runs.where("total_count > 0").limit(n)
  end


  def duration(n=20)
    durations = last_completed_test_runs(n).pluck(:duration).map { |n| n / 1000.0 }
    ljust(durations, 0, n).reverse
  end


  def coverage(n=20)
    percentages = last_completed_test_runs(n).pluck(:covered_percent).map { |n| n * 100.0 }
    ljust(percentages, 0.0, n).reverse
  end



  def tests(n=20)
    [ skips(n), regressions(n), fails(n), passes(n) ]
  end

  def skips(n=20)
    ljust(last_completed_test_runs(n).pluck(:skip_count), 0, n).reverse
  end

  def regressions(n=20)
    ljust(last_completed_test_runs(n).pluck(:regression_count), 0, n).reverse
  end

  def fails(n=20)
    ljust(last_completed_test_runs(n).pluck(:fail_count), 0, n).reverse
  end

  def passes(n=20)
    ljust(last_completed_test_runs(n).pluck(:pass_count), 0, n).reverse
  end



  def ljust(array, value, n)
    array.dup.fill(value, array.length...n)
  end

end
