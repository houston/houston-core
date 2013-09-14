require 'test_helper'

class CodeClimateCoverageReportTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  
  test "#ci_info should give the Jenkins build URL and build number" do
    project = Project.new(name: "Test", slug: "test", ci_server_name: "Jenkins")
    test_run = TestRun.new(project: project, sha: "45", branch: "master", results_url: "https://ci.example.com/job/test/319/")
    report = CodeClimate::CoverageReport.new(test_run)
    
    expected_ci_info = {
      name:             "jenkins",
      build_identifier: "319",
      build_url:        "https://ci.example.com/job/test/319/",
      branch:           "master",
      commit_sha:       "45"
    }
    
    assert_equal expected_ci_info, report.ci_info
  end
  
  
  test "#blob_id_of should return the blob_id of a file for a particular commit" do
    project = Project.new(
      name: "Test",
      slug: "test",
      ci_server_name: "Jenkins",
      version_control_name: "Git",
      extended_attributes: { "git_location" => Rails.root.join("test/data/bare_repo.git").to_s })
    test_run = TestRun.new(project: project, sha: "22924bb", branch: "master")
    report = CodeClimate::CoverageReport.new(test_run)
    
    assert_equal "ccf4bdedd71011176c0236e98268d71ed73eb80f", report.blob_id_of("README.md")
  end
  
  
end
