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
  
  
  test "#commit returns a Commit for the test_run's sha" do
    path = Rails.root.join("test", "data", "bare_repo.git").to_s
    project = Project.new(
      name: "Test",
      slug: "test",
      version_control_name: "Git",
      extended_attributes: { "git_location" => path })
    test_run = TestRun.new(sha: "b62c3f3", project: project)
    
    commit = test_run.commit
    assert_instance_of Commit, commit
    assert_match /^b62c3f3/, commit.sha
  end
  
  
  test "#coverage_detail returns SourceFileCoverage objects for each tested file" do
    project = Project.new(name: "Test", slug: "test", code_climate_repo_token: "repo_token")
    test_run = TestRun.new(project: project, sha: "bd3e9e2", result: "pass", completed_at: Time.now, coverage: [
      { filename: "lib/test1.rb", coverage: [1,nil,nil,1,1,nil,1] },
      { filename: "lib/test2.rb", coverage: [1,nil,1,0,0,0,0,1,nil,1] }
    ])
    
    stub(project).read_file { |*args| "" }
    
    files = test_run.coverage_detail
    assert_equal 2, files.length
    assert_instance_of SourceFileCoverage, files[0]
    assert_equal "lib/test2.rb", files[1].filename
  end
  
  
end
