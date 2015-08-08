require "test_helper"
require "support/houston/adapters/ci_server/mock_adapter"

class TestRunTest < ActiveSupport::TestCase
  attr_reader :project, :tr, :commit
  
  
  test "#retry! should trigger a new build" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    test_run = TestRun.new(sha: "whatever", result: "pass", project: project)
    
    mock(project.ci_server).build!(test_run.sha)
    test_run.retry!
  end
  
  
  test "#completed! should fetch test results (even if this test run is a retry)" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Mock")
    test_run = TestRun.new(sha: "whatever", result: "pass", project: project)
    results_url = "whatever"
    
    stub(test_run).save! { } # skip the database
    stub(test_run).fire_complete! { } # skip the callbacks
    
    mock(project.ci_server).fetch_results!(results_url).returns({})
    test_run.completed!(results_url)
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
      test_run = TestRun.create!(sha: "b62c3f3", project: project)
      assert_difference "Test.count", +2 do
        test_run.tests = @test_results
      end
    end

    should "find tests that have already been created" do
      project.tests.create!(
        suite: "ChangeTest",
        name: "should have a tag when created for a slug that has been aliased to a tag")
      project.tests.create!(
        suite: "ChangeTest",
        name: "should have a tag when created for a slug that has been associated with a tag")

      test_run = TestRun.create!(sha: "b62c3f3", project: project)
      assert_no_difference "Test.count" do
        test_run.tests = @test_results
      end
    end

    should "create test results" do
      test_run = TestRun.create!(sha: "b62c3f3", project: project)
      assert_difference "TestResult.count", +2 do
        test_run.tests = @test_results
      end
    end

    context "when a result contains an error" do
      setup do
        @test_results = [{
          age: 13,
          duration: 1.9763,
          error_message: "undefined method `git_dir' for #<Houston::Adapters::VersionControl::NullRepoClass:0xa176470> (NoMethodError)",
          error_backtrace: example_backtrace,
          name: "#git dir should return path when the repo is bare",
          status: "fail",
          suite: "GitAdapterTest" }]
      end

      should "create error records for the result" do
        test_run = TestRun.create!(sha: "b62c3f3", project: project)

        assert_difference "TestError.count", +1 do
          test_run.tests = @test_results
        end
      end

      should "find the appropriate error if it already exists" do
        output = [
          @test_results[0][:error_message],
          @test_results[0][:error_backtrace].join("\n") ].join("\n\n")
        TestError.create!(output: output)
        test_run = TestRun.create!(sha: "b62c3f3", project: project)

        assert_no_difference "TestError.count" do
          test_run.tests = @test_results
        end
      end
    end
  end
  
  
  
  test "#coverage_detail returns SourceFileCoverage objects for each tested file" do
    project = Project.new(name: "Test", slug: "test", code_climate_repo_token: "repo_token")
    test_run = TestRun.new(project: project, sha: "bd3e9e2", result: "pass", completed_at: Time.now, coverage: [
      { filename: "lib/test1.rb", coverage: [1,nil,nil,1,1,nil,1] },
      { filename: "lib/test2.rb", coverage: [1,nil,1,0,0,0,0,1,nil,1] }
    ])
    
    stub(project).read_file { |*args| "line 1\nline 2\n" }
    
    files = test_run.coverage_detail
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
  
  
  
private
  
  def example_backtrace
    [ "/var/lib/jenkins/home/jobs/houston/workspace/test/unit/git_adapter_test.rb:8:in `block in <class:GitAdapterTest>'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:1058:in `run'",
      "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit/testcase.rb:17:in `run'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:36:in `block in run'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:425:in `_run__300096475__setup__29189092__callbacks'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:405:in `__run_callback'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:385:in `_run_setup_callbacks'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:81:in `run_callbacks'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:35:in `run'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:175:in `run_test'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:102:in `_run_test'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:93:in `block in _run_suite'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `each'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `_run_suite'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `block in _run_suites'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `map'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `_run_suites'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:75:in `_run_anything'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:964:in `run_tests'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:951:in `block in _run'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `each'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `_run'",
      "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:939:in `run'",
      "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:21:in `run'",
      "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:326:in `block (2 levels) in autorun'",
      "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:27:in `run_once'",
      "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:325:in `block in autorun'" ]
  end
  
end
