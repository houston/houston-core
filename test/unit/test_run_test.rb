require 'test_helper'

class TestRunTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  
  test "#retry! triggers a new build" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    test_run = TestRun.new(sha: "whatever", result: "pass", project: project)
    
    mock(project.ci_server).build!(test_run.sha)
    test_run.retry!
  end
  
  
  test "#completed! fetches test results (even if this test run is a retry)" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    test_run = TestRun.new(sha: "whatever", result: "pass", project: project)
    results_url = "whatever"
    
    stub(test_run).save! { } # skip the database
    stub(test_run).fire_complete! { } # skip the callbacks
    
    mock(project.ci_server).fetch_results!(results_url)
    test_run.completed!(results_url)
  end
  
  
end
