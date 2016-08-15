require "test_helper"

class ProjectOptionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  attr_reader :project

  setup do
    sign_in User.first
    @project = create(:project,
      props: {
        "view.speed" => "plaid",
        "view.helmet" => "dark" })
  end


  context "#update" do
    should "merge supplied options with the project's options" do
      expected_options = {
        "view.speed" => "light",
        "view.helmet" => "dark",
        "view.schwartz" => "up side" }

      put :update, params: { slug: "test", options: {"view.speed" => "light", "view.schwartz" => "up side"} }
      assert_response :ok
      assert_equal expected_options, project.reload.props.to_h
    end
  end


  context "#destroy" do
    should "remove the specified key from the project's options" do
      expected_options = {
        "view.speed" => "plaid" }

      delete :destroy, params: { slug: "test", key: "view.helmet" }
      assert_response :ok
      assert_equal expected_options, project.reload.props.to_h
    end
  end


end
