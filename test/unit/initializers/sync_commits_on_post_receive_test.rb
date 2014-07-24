require "test_helper"


class SyncCommitsOnPostReceiveTest < ActiveSupport::TestCase
  
  context "When GitHub posts to /projects/:slug/hooks/post_receive, Houston" do
    should "sync commits for that project" do
      project = create(:project, version_control_name: "Mock")
      mock(project.commits).sync!
      Houston.observer.fire "hooks:post_receive", project, {}
    end
  end
  
end
