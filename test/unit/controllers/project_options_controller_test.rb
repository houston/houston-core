require "test_helper"

class ProjectOptionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  attr_reader :project

  setup do
    sign_in User.first
    @project = create(:project,
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
