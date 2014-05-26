require "test_helper"
require "support/houston/adapters/version_control/mock_adapter"

class SyncCommitsOnPostReceiveTest < ActionDispatch::IntegrationTest
  include RR::Adapters::TestUnit
  
  context "When GitHub posts to /projects/:slug/hooks/post_receive, Houston" do
    should "sync commits for that project" do
      @project = Project.create!(name: "Test", slug: "test", version_control_name: "Mock")
      
      mock(Houston::Adapters::VersionControl::NullRepo).refresh!
      
      post "/projects/#{@project.slug}/hooks/post_receive"
    end
  end
  
end
