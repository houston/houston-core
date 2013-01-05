require "test_helper"
require "support/houston/ci/adapter/mock_adapter"


# Tests config/initializers/run_tests_on_post_receive.rb
class CIIntegrationTest < ActionController::IntegrationTest
  include RR::Adapters::TestUnit
  
  
  test "should trigger a build when the hooks:post_receive event is fired for a project that uses a CI server" do
    @project = Project.create!(name: "Test", slug: "test", ci_adapter: "Mock")
    
    assert_difference "TestRun.count", +1 do
      post "/projects/#{@project.slug}/hooks/post_receive"
      assert_response :success
    end
  end
  
  test "should do nothing when the hooks:post_receive event is fired for a project that does not use a CI server" do
    @project = Project.create!(name: "Test", slug: "test", ci_adapter: "None")
    
    assert_no_difference "TestRun.count" do
      post "/projects/#{@project.slug}/hooks/post_receive"
      assert_response :success
    end
  end
  
  test "should alert maintainers when a build cannot be triggered" do
    @project = Project.create!(name: "Test", slug: "test", ci_adapter: "Mock")
    
    any_instance_of(Houston::CI::Adapter::MockAdapter::Job) do |job|
      stub(job).build! { |commit| raise Houston::CI::Error }
    end
    
    assert_no_difference "TestRun.count" do
      post "/projects/#{@project.slug}/hooks/post_receive"
      assert_response :success
      
      configuration_error = ActionMailer::Base.deliveries.last
      assert_not_nil configuration_error, "No deliveries have been recorded"
      assert_equal "Test: configuration error", configuration_error.subject
    end
  end
  
  test "should fetch results_url when the hooks:post_build event is fired" do
    expected_commit = "whatever"
    expected_results_url = "http://example.com/results"
    @project = Project.create!(name: "Test", slug: "test", ci_adapter: "Mock")
    @test_run = TestRun.create!(project: @project, commit: expected_commit)
    
    any_instance_of(Houston::CI::Adapter::MockAdapter::Job) do |job|
      mock(job).fetch_results!(expected_results_url)
    end
    
    assert_no_difference "TestRun.count" do
      post "/projects/#{@project.slug}/hooks/post_build", {commit: expected_commit, results_url: expected_results_url}
      assert_response :success
    end
  end
  
  
end
