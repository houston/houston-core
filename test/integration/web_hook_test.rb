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
  
  test "should trigger a hook when it is defined" do
    assert_triggered "hooks:whatever" do
      post "/projects/#{project.slug}/hooks/whatever"
      assert_response :success
    end
  end
  
  
  # !nb: this tests code that exists in config.rb (!!)
  if Houston.observer.observed?("hooks:exception_report")
    context "when being notified of an exception" do
      should "not report any exceptions" do
        begin
          mock(Houston.observer).fire(anything, anything, anything) { raise "hell" }
          post "/projects/#{project.slug}/hooks/exception_report"
        rescue
        end
        assert Airbrake.sender.collected.empty?, "Houston sent an exception report to Airbrake from a hook receiving an exception report. This could get ugly."
      end
    end
  end
  
  
end
