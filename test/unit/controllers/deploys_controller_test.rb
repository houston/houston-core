require "test_helper"


class DeploysControllerTest < ActionController::TestCase
  
  setup do
    @project = create(:project, ci_server_name: "Mock")
    @environment = "Production"
  end
  
  
  test "should not require a logged in user" do
    mock(Deploy).create!(project: @project, environment_name: @environment, sha: "hi", deployer: nil)
    post :create, project_id: @project.slug, environment: @environment, commit: "hi"
  end
  
  
  test "should work with a Heroku-style deploy hook" do
    mock(Deploy).create!(project: @project, environment_name: @environment, sha: "hi", deployer: "deployer@heroku.com")
    post :create, project_id: @project.slug, environment: @environment, head_long: "hi", user: "deployer@heroku.com"
  end
  
  
  test "should work with lowercased environments" do
    mock(Deploy).create!(project: @project, environment_name: @environment, sha: "hi", deployer: nil)
    post :create, project_id: @project.slug, environment: "production", commit: "hi"
  end
  
  
  test "should record the deployer if it is supplied" do
    mock(Deploy).create!(project: @project, environment_name: @environment, sha: "hi", deployer: "Bob Lail <bob.lail@cph.org>")
    post :create, project_id: @project.slug, environment: @environment, commit: "hi", deployer: "Bob Lail <bob.lail@cph.org>"
  end
  
  
end
