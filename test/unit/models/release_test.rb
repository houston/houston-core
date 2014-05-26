require "test_helper"

class ReleaseTest < ActiveSupport::TestCase
  attr_reader :release, :project
  
  setup do
    @project = Project.new(name: "Test", slug: "test", version_control_name: "Mock")
  end
  
  
  context "a new release" do
    setup do
      @release = Release.new(user_id: 1)
      stub(release).native_commits { nil }
    end
    
    should "trigger `release!` on each ticket" do
      a_ticket = Object.new
      stub(release).tickets { [a_ticket] }
      stub(release).antecedents { [] }
      mock(a_ticket).release!(release)
      release.save!
    end
    
    should "trigger `release!` on each antecedent" do
      an_antecedent = TicketAntecedent.new(nil, "Test", 4)
      stub(release).antecedents { [an_antecedent] }
      mock(an_antecedent).release!(release)
      release.save!
    end
    
    should "trigger `release!` on each task" do
      a_task = Object.new
      stub(release).tasks { [a_task] }
      stub(release).antecedents { [] }
      mock(a_task).release!(release)
      release.save!
    end
    
    
    
    context "when assigning commit0" do
      should "identify the before-commit" do
        commit = Commit.new(sha: "b62c3f32f72423b81a0282a1a4b97cad2cf129d4")
        stub(project).find_commit_by_sha(anything).returns(commit)
        release = Release.new(project: project, commit0: commit.sha[0...8])
        assert_equal commit, release.commit_before
      end
    end
    
    context "when assigning commit1" do
      should "identify the after-commit" do
        commit = Commit.new(sha: "b62c3f32f72423b81a0282a1a4b97cad2cf129d4")
        stub(project).find_commit_by_sha(anything).returns(commit)
        release = Release.new(project: project, commit1: commit.sha[0...8])
        assert_equal commit, release.commit_after
      end
    end
  end
  
  
end
