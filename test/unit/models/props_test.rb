require "test_helper"

class PropsTest < ActiveSupport::TestCase
  attr_reader :user

  should "raise an exception for an invalid prop name" do
    assert_raises do
      user = User.first
      user.update_prop! "slack_user_name", "slackbot"
    end
  end

  context "Given a user with the prop slack.username, it" do
    setup do
      @user = create(:user, props: {"slack.username" => "slackbot"})
    end

    should "be able to look up the user by that prop" do
      assert_equal user, User.find_by_prop("slack.username", "slackbot")
    end
  end

  context "When .find_by_prop is used with a block" do
    context "and a user exists with the queried prop, the block" do
      setup do
        @user = create(:user, props: {"slack.username" => "slackbot"})
      end

      should "not be invoked" do
        invoked = false
        User.find_by_prop("slack.username", "slackbot") { invoked = true }
        refute invoked, "Expected the block not to be invoked: the user was found"
      end
    end

    context "and a user does not exist with the queried prop," do
      context "the block" do
        should "be invoked the first time the user is looked up" do
          invoked = false
          User.find_by_prop("slack.username", "slackbot") { invoked = true; User.first }
          assert invoked, "Expected the block to be invoked: the user wasn't found"
        end

        should "not be invoked the second time the user is looked up" do
          invoked = false
          User.find_by_prop("slack.username", "slackbot") { invoked = true; User.first }
          assert invoked, "Expected the block to be invoked: the user wasn't found"

          invoked = false
          User.find_by_prop("slack.username", "slackbot") { invoked = true; User.first }
          refute invoked, "Expected the block not to be invoked: the user should've been mapped the first time"
        end
      end
    end
  end

end
