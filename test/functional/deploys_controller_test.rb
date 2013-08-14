require "test_helper"


class DeploysControllerTest < ActionController::TestCase
  include RR::Adapters::TestUnit
  
  setup do
    @project = Project.create!(name: "Test", slug: "test", ci_server_name: "Mock")
    @environment = "Production"
  end
  
  
  test "should not require a logged in user" do
    mock(Deploy).create!({project: @project, environment_name: @environment, commit: "hi"})
    post :create, {project_id: @project.slug, environment: @environment, commit: "hi"}
  end
  
  
  test "should work with a Heroku-style deploy hook" do
    mock(Deploy).create!({project: @project, environment_name: @environment, commit: "hi"})
    post :create, {project_id: @project.slug, environment: @environment, head_long: "hi"}
  end
  
  
  test "should work with lowercased environments" do
    mock(Deploy).create!({project: @project, environment_name: @environment, commit: "hi"})
    post :create, {project_id: @project.slug, environment: "production", commit: "hi"}
  end
  
  
end
