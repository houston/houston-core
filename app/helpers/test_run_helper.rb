module TestRunHelper
  include ActionView::Helpers::DateHelper
  
  def test_run_summary(test_run)
    subject = {
      "pass" => "#{test_run.total_count} tests passed!",
      "fail" => "#{test_run.fail_count} of #{test_run.total_count} tests failed",
      "" => "started #{distance_of_time_in_words(test_run.created_at, Time.now)} ago"
    }[test_run.result.to_s]
  end
  
end
