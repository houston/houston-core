require "test_helper"


class WebHookTest < ActionController::IntegrationTest
  
  setup do
    @project = Project.create!(name: "Test", slug: "test")
  end
  
  
  test "should return 404 when a project is not defined" do
    post "/projects/nope/hooks/post_receive"
    assert_response :not_found
  end
  
  test "should return 404 when a hook is not defined" do
    post "/projects/#{@project.slug}/hooks/nope"
    assert_response :not_found
  end
  
  test "should trigger a hook when it is defined" do
    assert_triggered "hooks:whatever" do
      post "/projects/#{@project.slug}/hooks/whatever"
      assert_response :success
    end
  end
  
end
