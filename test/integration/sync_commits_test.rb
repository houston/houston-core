require "test_helper"
require "support/houston/adapters/version_control/mock_adapter"


# Tests config/initializers/sync_commits_on_post_receive.rb
class SyncCommitsTest < ActionDispatch::IntegrationTest
  include RR::Adapters::TestUnit
  
  
  
  test "should sync commits on hooks:post_receive" do
    @project = Project.create!(name: "Test", slug: "test", version_control_name: "Mock")
    
    mock(Houston::Adapters::VersionControl::NullRepo).refresh!
    
    post "/projects/#{@project.slug}/hooks/post_receive"
  end
  
  
  
end
