require "test_helper"


class WebHookTest < ActionController::IntegrationTest
  
  
  test "should trigger the corresponding event" do
    project = Project.create!(name: "Test", slug: "test")
    
    event_triggered = false
    Houston.observer.on "hooks:post_receive" do
      event_triggered = true
    end
    
    post "/projects/#{project.slug}/hooks/post_receive"
    
    assert_response :success
    assert event_triggered, "The event 'hooks:post_receive' was not triggered"
  end
  
  
end
