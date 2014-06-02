require "test_helper"

class CreatingAReleaseTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  attr_reader :user, :project, :ticket, :commit0, :commit1
  fixtures :all
  
  
  setup do
    @commit0 = "e558039"
    @commit1 = "07fc2de"
    
    @user = User.first
    @project = Project.create!(
      name: "Houston",
      slug: "houston",
      ticket_tracker_name: "Houston",
      version_control_name: "Git",
      extended_attributes:  {"git_location" => Rails.root.join(".git")})
    @project.roles.create!(name: "Maintainer", user: user)
    @ticket = @project.tickets.create!(
      number: 116,
      type: "Bug",
      summary: "Make links in the ticket modal open a new window")
    
    visit "/users/sign_in"
    fill_in "user_email", with: "bob@example.com"
    fill_in "user_password", with: "password"
    click_button "Sign in"
  end
  
  teardown do
    Capybara.reset_sessions!
  end
  
  
  context "Given a valid commit range" do
    should "show the release form" do
      visit new_release_path
      
      assert page.has_content?("New Release to Production")
    end
    
    should "show all the commits" do
      visit new_release_path
      
      project.commits.between(commit0, commit1).each do |commit|
        assert page.has_content?(commit.summary), "Expected to find commit #{commit} on the page"
      end
    end
    
    should "show ticket #116, which was mentioned by one of the commits" do
      visit new_release_path
      
      assert page.has_content?(ticket.summary), "Expected to find ticket #{ticket.number} on the page"
    end
  end
  
  
  context "When creating the release" do
    setup do
      visit new_release_path
    end
    
    should "create the release" do
      assert_difference "Release.count", +1 do
        click_button "Create Release"
      end
    end
  end
  
  
private
  
  def new_release_path
    "/projects/houston/environments/Production/releases/new?commit0=#{commit0}&commit1=#{commit1}"
  end
  
end
