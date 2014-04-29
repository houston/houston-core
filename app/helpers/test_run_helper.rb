module TestRunHelper
  
  def test_status(test)
    return "pass" if test[:status] == :pass
    "fail" # may be :fail or :regresion
  end
  
  def test_run_summary(test_run)
    subject = {
      "pass" => "#{test_run.total_count} tests passed!",
      "fail" => "#{test_run.real_fail_count} of #{test_run.total_count} tests failed",
      "error" => "tests are broken",
      "aborted" => "aborted"
    }.fetch(
      test_run.result.to_s,
      (test_run.created_at ? "started #{distance_of_time_in_words(test_run.created_at, Time.now)} ago" : ""))
    
    subject << " [#{test_run.branch}]" if test_run.branch
    
    subject
  end
  
end
