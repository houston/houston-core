require "test_helper"
require "support/houston/adapters/ci_server/mock_adapter"

class TestRunTest < ActiveSupport::TestCase
  attr_reader :project, :tr, :commit
  
  
  test "#retry! should trigger a new build" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    tr = TestRun.new(sha: "whatever", result: "pass", project: project)
    
    mock(project.ci_server).build!(tr.sha)
    tr.retry!
  end
  
  
  test "#completed! should fetch test results (even if this test run is a retry)" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    tr = TestRun.new(sha: "whatever", result: "pass", project: project)
    results_url = "whatever"
    
    stub(tr).save! { } # skip the database
    stub(tr).fire_complete! { } # skip the callbacks
    
    mock(project.ci_server).fetch_results!(results_url).returns({})
    tr.completed!(results_url)
  end
  
  
  
  context "#tests=" do
    setup do
      @test_results = [
        { age: 0,
          duration: 1.334,
          name: "should have a tag when created for a slug that has been aliased to a tag",
          status: "pass",
          suite: "ChangeTest" },
        { age: 0,
          duration: 0.9964,
          name: "should have a tag when created for a slug that has been associated with a tag",
          status: "pass",
          suite: "ChangeTest" }]

      path = Rails.root.join("test", "data", "bare_repo.git").to_s
      @project = Project.create!(
        name: "Test",
        slug: "test",
        version_control_name: "Git",
        extended_attributes: { "git_location" => path })
    end

    should "create tests for the project" do
      tr = TestRun.create!(sha: "b62c3f3", project: project)
      assert_difference "Test.count", +2 do
        tr.update_attribute :tests, @test_results
      end
    end

    should "find tests that have already been created" do
      project.tests.create!(
        suite: "ChangeTest",
        name: "should have a tag when created for a slug that has been aliased to a tag")
      project.tests.create!(
        suite: "ChangeTest",
        name: "should have a tag when created for a slug that has been associated with a tag")

      tr = TestRun.create!(sha: "b62c3f3", project: project)
      assert_no_difference "Test.count" do
        tr.update_attribute :tests, @test_results
      end
    end

    should "create test results" do
      tr = TestRun.create!(sha: "b62c3f3", project: project)
      assert_difference "TestResult.count", +2 do
        tr.update_attribute :tests, @test_results
      end
    end

    context "when a result contains an error" do
      setup do
        @test_results = [{
          age: 13,
          duration: 1.9763,
          error_message: "undefined method `git_dir' for #<Houston::Adapters::VersionControl::NullRepoClass:0xa176470> (NoMethodError)",
          error_backtrace: File.read("test/data/backtrace.txt").split(/\n/),
          name: "#git dir should return path when the repo is bare",
          status: "fail",
          suite: "GitAdapterTest" }]
      end

      should "create error records for the result" do
        tr = TestRun.create!(sha: "b62c3f3", project: project)

        assert_difference "TestError.count", +1 do
          tr.update_attribute :tests, @test_results
        end
      end

      should "find the appropriate error if it already exists" do
        output = [
          @test_results[0][:error_message],
          @test_results[0][:error_backtrace].join("\n") ].join("\n\n")
        TestError.create!(output: output)
        tr = TestRun.create!(sha: "b62c3f3", project: project)

        assert_no_difference "TestError.count" do
          tr.update_attribute :tests, @test_results
        end
      end
    end
  end
  
  
  
  test "#coverage_detail returns SourceFileCoverage objects for each tested file" do
    project = Project.new(name: "Test", slug: "test", code_climate_repo_token: "repo_token")
    tr = TestRun.new(project: project, sha: "bd3e9e2", result: "pass", completed_at: Time.now, coverage: [
      { filename: "lib/test1.rb", coverage: [1,nil,nil,1,1,nil,1] },
      { filename: "lib/test2.rb", coverage: [1,nil,1,0,0,0,0,1,nil,1] }
    ])
    
    stub(project).read_file { |*args| "line 1\nline 2\n" }
    
    files = tr.coverage_detail
    assert_equal 2, files.length
    assert_instance_of SourceFileCoverage, files[0]
    assert_equal "lib/test2.rb", files[1].filename
  end
  
  
  
  context "a new test run" do
    setup do
      @project = create(:project, version_control_name: "Mock")
      @tr = TestRun.new(project: project)
    end
    
    context "for a valid commit" do
      setup do
        @commit = Commit.new(sha: "edd44727c05c93b34737cb48873929fb5af69885")
        tr.sha = "#{commit.sha[0...8]}\n"
        mock(project).find_commit_by_sha(anything).returns(commit)
      end
      
      should "associate itself with the specified commit" do
        tr.save!
        assert_equal commit, tr.commit
      end
      
      should "normalize the sha as well" do
        tr.save!
        assert_equal commit.sha, tr.sha
      end
      
      
      context "and a recognizable email address" do
        setup do
          @user = User.first
          tr.agent_email = "Test <#{@user.email}>"
        end
      
        should "associate itself with the specified user" do
          tr.save!
          assert_equal @user, tr.user, "Expected the test run to be associated with the user"
        end
      end
    end
    
    context "for an invalid commit" do
      setup do
        mock(project).find_commit_by_sha(anything) do
          raise Houston::Adapters::VersionControl::InvalidShaError
        end
        tr.sha = "whatever\n"
      end
      
      should "save with the given sha" do
        assert tr.valid?, "Expected the test run to be valid"
      end
      
      should "not be associated with a commit" do
        tr.save!
        refute tr.commit, "Expected the test run not to be associated with a commit"
      end
    end
  end
  
  
  
  context "Given a commit history," do
    setup do
      @project = Project.create!(name: "Test", slug: "test", version_control_name: "Mock")
      @commit_a = create(:commit, project: project, sha: "a")
      @commit_b = create(:commit, project: project, sha: "b", parent_sha: "a")
      @commit_c = create(:commit, project: project, sha: "c", parent_sha: "b")
      @tr = TestRun.new(project: project, sha: "c", commit: @commit_c)
      stub(tr).fetch_results! { }
      stub(tr).save! { }
      stub(tr).has_results? { true }
    end
    
    context "when a test run is completed" do
      context "for a commit whose parent doesn't have a test run, it" do
        should "create a test run for its parent if the test run is failing" do
          stub(tr).fetch_results! { tr.update_attribute :result, "fail" }
          mock(tr.commit.parent).create_test_run!
          tr.completed!("http://results")
        end
        
        should "not create a test run for its parent if the test run is passing" do
          stub(tr).fetch_results! { tr.update_attribute :result, "pass" }
          mock(tr.commit.parent).create_test_run!.never
          tr.completed!("http://results")
        end
      end
      
      context "for a commit whose parent has a pending test run, it" do
        should "do nothing (and wait for the test run to complete)" do
          mock(TestRunComparer).compare!.with_any_args.never
          tr.completed!("http://results")
        end
      end
      
      context "for a commit whose parent has a completed test run, it" do
        setup do
          @parent_test_run = TestRun.create!(
            project: project,
            sha: "b",
            results_url: "http://results",
            completed_at: Time.now)
        end
        
        should "compare its results with its parent's" do
          mock(TestRunComparer).compare!(@parent_test_run, tr)
          stub(tr.commit.parent.test_run).compare_results!
          tr.completed!("http://results")
        end
        
        should "then analyze the parent's parent!" do
          stub(TestRunComparer).compare!
          mock(tr.commit.parent.test_run).compare_results!
          tr.completed!("http://results")
        end
      end
      
      context "when a test run has already been compared" do
        setup do
          @parent_test_run = TestRun.create!(
            project: project,
            sha: "b",
            results_url: "http://results",
            completed_at: Time.now)
          tr.update_attribute :compared, true
        end
        
        should "not compare its results with its parent's" do
          mock(TestRunComparer).compare!.with_any_args.never
          tr.completed!("http://results")
        end
      end
    end
  end
  
  
end
