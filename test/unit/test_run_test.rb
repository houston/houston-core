require 'test_helper'

class TestRunTest < ActiveSupport::TestCase
  
  
  setup do
    @project = Project.new(name: "Test Project", slug: "test")
    @test_run = TestRun.new(project: @project)
  end
  
  
  test "should generate a callback path that corresponds to the post_build web hook" do
    expected_path = Rails.application.routes.url_helpers
      .web_hook_path(project_id: "test", hook: "post_build")
    assert_equal expected_path, @test_run.callback_path
  end
  
  
end
