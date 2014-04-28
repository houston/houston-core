require 'test_helper'

class ReleaseTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  attr_reader :release, :project
  
  
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
  end
  
  
  context "Given a project that uses Git" do
    setup do
      @project = Project.new
      test_repo = Houston::Adapters::VersionControl::GitAdapter.build(project,
        Rails.root.join("test", "data", "bare_repo.git"))
      stub(project).repo.returns(test_repo)
    end
    
    context "before saving a release" do
      setup do
        @expected_sha = "b62c3f32f72423b81a0282a1a4b97cad2cf129d4"
        @release = Release.new(project: project, commit1: @expected_sha[0...8])
      end
      
      should "normalize the commit SHAs" do
        release.valid?
        assert_equal @expected_sha, release.commit1
      end
    end
  end
  
  
end
