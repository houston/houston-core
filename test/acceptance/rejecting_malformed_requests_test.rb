require "test_helper"

class RejectingMalformedRequestsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  context "Given a malformed request, it" do
    should "respond with 400 rather than raising an exception" do
      assert_nothing_raised do
        visit "/users/sign_in?user[password]=%FF%FE%3C%73%63%72%69%70%74%3E%61%6C%65%72%74%28%32%30%33%29%3C%2F%73%63%72%69%70%74%3E"
      end
    end
  end

end
