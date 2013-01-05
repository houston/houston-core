require "test_helper"


class WebHookTest < ActionController::IntegrationTest
  
  
  # !warning: knows an _awful_ lot about Houston::Observer's implementation!
  # Intended to keep Houston from firing the _actual_ post_receive hooks
  setup do
    @observers = Houston.observer.instance_variable_get(:@observers)
    Houston.observer.clear!
  end
  
  teardown do
    Houston.observer.instance_variable_set(:@observers, @observers)
  end
  
  
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
