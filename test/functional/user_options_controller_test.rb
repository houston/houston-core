require "test_helper"

class UserOptionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  include RR::Adapters::TestUnit
  
  attr_reader :user
  
  setup do
    @user = User.create!(
      first_name: "Bob",
      last_name: "Lail",
      email: "bob.lail@houston.test",
      password: "password",
      password_confirmation: "password",
      view_options: {
        "speed" => "plaid",
        "helmet" => "dark" })
    sign_in @user
  end
  
  
  context "#update" do
    should "merge supplied options with the project's options" do
      expected_options = {
        "speed" => "light",
        "helmet" => "dark",
        "schwartz" => "up side" }
    
      put :update, options: {speed: "light", schwartz: "up side"}
      assert_response :ok
      assert_equal expected_options, user.reload.view_options
    end
  end
  
  
  context "#destroy" do
    should "remove the specified key from the project's options" do
      expected_options = {
        "speed" => "plaid" }
      
      delete :destroy, key: "helmet"
      assert_response :ok
      assert_equal expected_options, user.reload.view_options
    end
  end
  
  
end
