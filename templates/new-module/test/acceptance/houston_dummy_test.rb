require "test_helper"

class DummyHoustonTest < ActionDispatch::IntegrationTest

  context "The Test Suite" do
    should "be able to interact with a dummy instance of Houston" do
      visit "/users/sign_in"
      fill_in "user_email", with: "admin@example.com"
      fill_in "user_password", with: "password"
      click_button "Sign in"

      assert page.has_content?("Teams"),
        "Expected to have been able to log in and to see the Teams view"
    end
  end

end
