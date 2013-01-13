require "test_helper"


class DeploysControllerTest < ActionController::TestCase
  include RR::Adapters::TestUnit
  
  
  test "should not require a logged in user" do
    @project = Project.create!(name: "Test", slug: "test", ci_adapter: "Mock")
    
    mock(Deploy).create!(anything)
    
    post :create, {project_id: "test", environment: "Production", commit: "hi"}
  end
  
  
end
