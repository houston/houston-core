require "test_helper"

class ProjectOptionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  attr_reader :project
  
  setup do
    sign_in User.create!(
      first_name: "Bob",
      last_name: "Lail",
      email: "bob.lail@houston.test",
      password: "password",
      password_confirmation: "password")
    @project = Project.create!(
      name: "Test",
      slug: "test",
      view_options: {
        "speed" => "plaid",
        "helmet" => "dark" })
  end
  
  
  context "#update" do
    should "merge supplied options with the project's options" do
      expected_options = {
        "speed" => "light",
        "helmet" => "dark",
        "schwartz" => "up side" }
    
      put :update, slug: "test", options: {speed: "light", schwartz: "up side"}
      assert_response :ok
      assert_equal expected_options, project.reload.view_options
    end
  end
  
  
  context "#destroy" do
    should "remove the specified key from the project's options" do
      expected_options = {
        "speed" => "plaid" }
      
      delete :destroy, slug: "test", key: "helmet"
      assert_response :ok
      assert_equal expected_options, project.reload.view_options
    end
  end
  
  
end
