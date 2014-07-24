require "test_helper"

class DeployTest < ActiveSupport::TestCase
  attr_reader :project, :deploy, :commit
  
  
  context "a new deploy" do
    setup do
      @project = create(:project, version_control_name: "Mock")
      @deploy = Deploy.new(project: project, environment_name: "Production")
    end
    
    context "for a valid commit" do
      setup do
        @commit = Commit.new(sha: "edd44727c05c93b34737cb48873929fb5af69885")
        @deploy.commit = "#{commit}\n"
        mock(project).find_commit_by_sha(anything).returns(commit)
      end
      
      should "associate itself with the specified commit" do
        deploy.save!
        assert_equal commit, deploy.commit
      end
    end
    
    context "for an invalid commit" do
      setup do
        mock(project).find_commit_by_sha(anything) do
          raise Houston::Adapters::VersionControl::InvalidShaError
        end
      end
      
      should "associate be invalid given an invalid sha" do
        deploy.commit = "whatever"
        refute deploy.valid?, "Expected the deploy not to be valid, given an invalid commit"
        assert_match /must refer to a valid commit/, deploy.errors.full_messages.join
      end
    end
  end
  
  
end
