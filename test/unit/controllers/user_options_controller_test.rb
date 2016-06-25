require "test_helper"

class UserOptionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  attr_reader :user

  setup do
    @user = create(:user,
      props: {
        "view.speed" => "plaid",
        "view.helmet" => "dark" })
    sign_in @user
  end


  context "#update" do
    should "merge supplied options with the user's options" do
      expected_options = {
        "view.speed" => "light",
        "view.helmet" => "dark",
        "view.schwartz" => "up side" }

      put :update, options: {"view.speed" => "light", "view.schwartz" => "up side"}
      assert_response :ok
      assert_equal expected_options, user.reload.props.to_h
    end
  end


  context "#destroy" do
    should "remove the specified key from the user's options" do
      expected_options = {
        "view.speed" => "plaid" }

      delete :destroy, key: "view.helmet"
      assert_response :ok
      assert_equal expected_options, user.reload.props.to_h
    end
  end


end
