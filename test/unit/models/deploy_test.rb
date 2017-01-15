require "test_helper"

class DeployTest < ActiveSupport::TestCase
  attr_reader :project, :deploy, :commit, :previous_deploy, :previous_commit

  setup do
    @project = create(:project, props: {"adapter.versionControl" => "Mock"})
  end



  context "a new deploy" do
    setup do
      @deploy = Deploy.new(project: project, environment_name: "production")
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


  context "The first deploy to a new environment" do
    setup do
      @deploy = create(:deploy, project: project)
    end

    should "have an empty commit range" do
      assert_equal [], deploy.commits
    end
  end


  context "A subsequent deploy to an environment" do
    setup do
      @previous_commit = Commit.new(sha: "2cd4f2bab9f7eb1104273b0283aa39f91215184e")
      stub(project).find_commit_by_sha(previous_commit.sha).returns(previous_commit)
      @previous_deploy = create(:deploy, project: project, sha: previous_commit.sha)

      # This is a red herring: an older commit
      stub(project).find_commit_by_sha("888f5c5").returns(nil)
      create(:deploy, project: project, sha: "888f5c5", completed_at: 1.week.ago)

      # This is a red herring: a more-recent commit to the wrong environment
      stub(project).find_commit_by_sha("30301ad").returns(nil)
      create(:deploy, project: project, sha: "30301ad", environment_name: "Nope")
    end

    context "with a valid commit" do
      setup do
        @commit = Commit.new(sha: "edd44727c05c93b34737cb48873929fb5af69885")
        stub(project).find_commit_by_sha(commit.sha).returns(commit)
        @deploy = with_exclusive_observation { create(:deploy, project: project, sha: commit.sha) }
      end

      should "be able to list the commits that were deployed" do
        mock(project.commits).between(previous_deploy.sha, commit.sha)
          .returns(:list_of_commits)
        assert_equal :list_of_commits, deploy.commits
      end
    end
  end


end
