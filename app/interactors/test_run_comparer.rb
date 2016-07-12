class TestRunComparer
  attr_reader :test_run1, :test_run2

  def self.compare!(test_run1, test_run2)
    self.new(test_run1, test_run2).compare!
  end

  def initialize(test_run1, test_run2)
    @test_run1 = test_run1
    @test_run2 = test_run2
  end

  def compare!
    return if test_run1.completed_without_running_tests? ||
              test_run2.completed_without_running_tests?

    TestRun.transaction do
      each_comparison do |result_id, status1, status2|
        if status1.nil?
          TestResult.where(id: result_id).update_all(different: false, new_test: true)
        elsif status1 == status2
          TestResult.where(id: result_id).update_all(different: false, new_test: false)
        else
          TestResult.where(id: result_id).update_all(different: true, new_test: false)
        end
      end

      test_run2.update_attribute :compared, true

      Houston.observer.fire "test_run:compared", test_run: test_run2
    end
  end

  def each_comparison(&block)
    Test.connection.select_all(<<-SQL).rows.each(&block)
    SELECT
      test_results2.id,
      test_results1.status,
      test_results2.status
    FROM (SELECT * FROM test_results WHERE test_run_id=#{test_run2.id}) "test_results2"
    LEFT OUTER JOIN (SELECT * FROM test_results WHERE test_run_id=#{test_run1.id}) "test_results1"
      ON test_results1.test_id=test_results2.test_id
    SQL
  end

end
