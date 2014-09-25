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
        deploy.sha = "#{commit.sha[0...8]}\n"
        mock(project).find_commit_by_sha(anything).returns(commit)
      end
      
      should "associate itself with the specified commit" do
        deploy.save!
        assert_equal commit, deploy.commit
      end
      
      should "normalize the sha as well" do
        deploy.save!
        assert_equal commit.sha, deploy.sha
      end
    end
    
    context "for an invalid commit" do
      setup do
        mock(project).find_commit_by_sha(anything) do
          raise Houston::Adapters::VersionControl::InvalidShaError
        end
        deploy.sha = "whatever\n"
      end
      
      should "save with the given sha" do
        assert deploy.valid?, "Expected the deploy to be valid"
      end
      
      should "not be associated with a commit" do
        deploy.save!
        refute deploy.commit, "Expected the deploy not to be associated with a commit"
      end
    end
  end
  
  
end
