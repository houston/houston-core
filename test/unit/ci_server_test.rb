require 'test_helper'

class CIServerTest < ActiveSupport::TestCase
  
  
  test "should generate a callback url that corresponds to the post_build web hook" do
    expected_url = Rails.application.routes.url_helpers
      .web_hook_url(host: Houston.config.host, project_id: "test", hook: "post_build")
    project = Project.new(name: "Test Project", slug: "test")
    assert_equal expected_url, Houston::CIServer.post_build_callback_url(project)
  end
  
  
end
