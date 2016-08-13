require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers


  context "Owners" do
    setup do
      sign_in owner
    end

    should "be able to change other users' roles" do
      put :update, id: a_user.id, user: {role: "Owner"}
      assert_equal "Owner", a_user.reload.role
    end

    should "not be able to change their own role" do
      put :update, id: owner.id, user: {role: "Member"}
      assert_equal "Owner", owner.reload.role
    end
  end


  context "Non-Owners" do
    setup do
      sign_in a_user
    end

    should "not be able to change their own role" do
      put :update, id: a_user.id, user: {role: "Owner"}
      refute_equal "Owner", a_user.reload.role
    end
  end


private

  def owner
    @owner ||= User.first
  end

  def a_user
    @a_user ||= create(:user)
  end

end
