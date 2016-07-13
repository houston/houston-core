require "test_helper"


class WebHookTest < ActionDispatch::IntegrationTest
  attr_reader :project

  setup do
    @project = create(:project)
  end


  test "should return 404 when a project is not defined" do
    post "/projects/nope/hooks/post_receive"
    assert_response :not_found
  end

  test "should return 404 when a hook is not defined" do
    post "/projects/#{project.slug}/hooks/nope"
    assert_response :not_found
  end

  test "should trigger a project hook when it is defined" do
    assert_triggered "hooks:project:whatever" do
      post "/projects/#{project.slug}/hooks/whatever"
      assert_response :success
    end
  end

  test "should trigger a generic hook when it is defined" do
    assert_triggered "hooks:whatever" do
      post "/hooks/whatever"
      assert_response :success
    end
  end

end
