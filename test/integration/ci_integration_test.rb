require "test_helper"
require "support/houston/ci/adapter/mock_adapter"


class CIIntegrationTest < ActionController::IntegrationTest
  
  
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
  
  
end
