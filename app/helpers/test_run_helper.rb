module TestRunHelper
  
  def test_run_summary(test_run)
    subject = {
      "pass" => "#{test_run.total_count} tests passed!",
      "fail" => "#{test_run.fail_count} of #{test_run.total_count} tests failed"
    }[test_run.result.to_s]
  end
  
end
