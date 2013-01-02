require 'test_helper'

class TestRunTest < ActiveSupport::TestCase
  
  
  setup do
    @project = Project.create!(name: "Test Project", slug: "test")
    @test_run = TestRun.new(project: @project)
  end
  
  
  test ".for should return a new valid TestRun if there's not already test run for the given commit" do
    test_run = @project.test_runs.for("acc899")
    assert_equal true, test_run.valid?, "The test run was not valid: #{test_run.errors.full_messages.to_sentence}"
  end
  
  
  test "should generate a callback url that corresponds to the post_build web hook" do
    expected_url = Rails.application.routes.url_helpers
      .web_hook_url(host: Houston.config.host, project_id: "test", hook: "post_build")
    assert_equal expected_url, @test_run.callback_url
  end
  
  
end
