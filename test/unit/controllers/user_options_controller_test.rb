require "test_helper"

class UserOptionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  attr_reader :user
  
  setup do
    @user = create(:user,
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
