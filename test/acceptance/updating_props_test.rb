require "test_helper"

# Given a runtime-defined field for project
Houston.view["edit_project"].add_field("Test Field") do |f|
  f.text_field "test.field", id: "__props_test_field"
end

# Given a runtime-defined field for user
Houston.view["edit_user"].add_field("Test Field") do |f|
  f.text_field "test.field", id: "__props_test_field"
end


class UpdatingPropersTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  attr_reader :project, :user


  setup do
    Capybara.reset_sessions!
    visit "/users/sign_in"
    fill_in "Username or Email", with: "bob@example.com"
    fill_in "Password", with: "password"
    click_button "Sign in"
  end


  context "A runtime-defined field for projects" do
    setup do
      @project = FactoryGirl.create(:project)
    end

    should "be rendered on the Edit Project view" do
      visit "projects/#{project.slug}/edit"

      assert page.has_selector? 'input[type="text"][name="project[props][test.field]"]'
    end

    should "be updated if changed on the Edit Project view" do
      visit "projects/#{project.slug}/edit"
      fill_in "Test Field", with: "NEW VALUE"
      click_button "Update Project"

      assert_equal "NEW VALUE", project.reload.props["test.field"]
    end
  end


  context "A runtime-defined field for users" do
    setup do
      @user = users(:boblail)
    end

    should "be rendered on the Edit Project view" do
      visit "users/#{user.id}/edit"

      assert page.has_selector? 'input[type="text"][name="user[props][test.field]"]'
    end

    should "be updated if changed on the Edit Project view" do
      visit "users/#{user.id}/edit"
      fill_in "Test Field", with: "NEW VALUE"
      click_button "Update User"

      assert_equal "NEW VALUE", user.reload.props["test.field"]
    end
  end


end
