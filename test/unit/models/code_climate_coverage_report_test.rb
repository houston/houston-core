require "test_helper"


class CodeClimateCoverageReportTest < ActiveSupport::TestCase
  attr_reader :sha, :report, :project, :test_run
  
  setup do
    @sha = "e0e4580f44317a084dd5142fef6b4144a4394819"
    @project = Project.new(
      name: "Test",
      slug: "test",
      ci_server_name: "Jenkins",
      version_control_name: "Git",
      extended_attributes: { "git_location" => Rails.root.join("test/data/bare_repo.git").to_s })
    @commit = Commit.new(project: @project, sha: @sha)
    @test_run = TestRun.new(
      project: project,
      sha: sha,
      commit: @commit,
      branch: "master",
      results_url: "https://ci.example.com/job/test/319/",
      coverage: [
        { filename: "README.md", coverage: [nil,nil,nil,nil] }, # 4 lines
        { filename: "lib/test1.rb", coverage: [1,nil,1,1,1,nil,1] }, # 7 lines; 5 covered
        { filename: "lib/test2.rb", coverage: [1,nil,1,0,0,0,0,1,nil,1,nil] } # 11 lines; 4 covered; 4 missed
      ])
    @report = CodeClimate::CoverageReport.new(test_run)
  end
  
  
  
  context "#code_climate_payload" do
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L58-L75
    should "include the right keys" do
      keys = [
        :repo_token,
        :source_files,
        :run_at,
        :covered_percent,
        :covered_strength,
        :line_counts,
        :partial,
        :git,
        :environment,
        :ci_service
      ]
      
      assert_equal keys, report.code_climate_payload.keys
    end
    
    context "/source_files" do
      should "contain one hash for each source file" do
        assert_equal 3, report.source_files.length
      end
      
      # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L44-L55
      should "include the right keys" do
        keys = [
          :name,
          :blob_id,
          :coverage,
          :covered_percent,
          :covered_strength,
          :line_counts
        ]

        source_file = report.source_files.first
        assert_equal keys, source_file.keys
      end
    end
    
    context "/run_at" do
      should "return an integer representing the time the TestRun completed" do
        time = Time.now
        test_run.completed_at = time
        assert_equal time.to_i, report.run_at
      end
    end
    
    context "/line_counts" do
      should "return the sum of all lines, covered lines, and missed lines from all source files" do
        expected_totals = { total: 22, covered: 9, missed: 4 }
        assert_equal expected_totals, report.line_counts
      end
    end
    
    context "/commit_info" do
      should "return the sha, commit time, and branch" do
        # head is the 40-character sha
        # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/git.rb#L8
        #
        # committed_at is an integer timestamp
        # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/git.rb#L30
        expected_commit_info = { head: sha, committed_at: 0, branch: "master" }
        assert_equal expected_commit_info, report.commit_info
      end
    end
    
    context "/environment" do
      should "return the right keys" do
        keys = [
          :test_framework,
          :pwd,
          :rails_root,
          :simplecov_root,
          :gem_version
        ]

        assert_equal keys, report.environment.keys
      end
    end
    
    context "/ci_service" do
      # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/ci.rb#L27-L33
      should "give the Jenkins build URL and build number" do
        expected_ci_service = {
          name:             "jenkins",
          build_identifier: "319",
          build_url:        "https://ci.example.com/job/test/319/",
          branch:           "master",
          commit_sha:       sha
        }

        assert_equal expected_ci_service, report.ci_service
      end
    end
  end
  
  
  
  test "#blob_id_of should return the blob_id of a file for a particular commit" do
    assert_equal "ccf4bdedd71011176c0236e98268d71ed73eb80f", report.blob_id_of("README.md")
  end
  
  
  
end
