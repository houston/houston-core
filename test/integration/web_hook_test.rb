require "test_helper"


class WebHookTest < ActionController::IntegrationTest
  
  setup do
    @project = Project.create!(name: "Test", slug: "test")
  end
  
  Houston.config.web_hooks.each do |hook|
    test "should trigger the #{hook} hook" do
      assert_triggered "hooks:#{hook}" do
        post "/projects/#{@project.slug}/hooks/#{hook}"
        assert_response :success
      end
    end
  end
  
end
