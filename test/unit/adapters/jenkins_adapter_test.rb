require "test_helper"

class JenkinsAdapterTest < ActiveSupport::TestCase


  test "#fetch_results! should correctly parse Jenkins build data" do
    build_url = "http://jenkins.com/job/houston/18"
    result_url = "#{build_url}/api/json?tree=result"
    test_report_url = "#{build_url}/testReport/api/json"
    coverage_report_url = "#{build_url}/artifact/coverage/coverage.json"

    expected_results = {
      result:       "fail",
      duration:     884.9784,
      total_count:  4,
      fail_count:   1,
      pass_count:   3,
      regression_count: 0,
      skip_count:   0,
      tests:        [{
        suite: "ChangeTest", name: "should have a tag when created for a slug that has been aliased to a tag",
        status: :pass, duration: 1.334, age: 0
      }, {
        suite: "ChangeTest", name: "should have a tag when created for a slug that has been associated with a tag",
        status: :pass, duration: 0.9964, age: 0,
      }, {
        suite: "GitAdapterTest", name: "#git dir should return path when the repo is bare",
        status: :fail, duration: 1.9763, age: 13,
        error_message: "undefined method `git_dir' for #<Houston::Adapters::VersionControl::NullRepoClass:0xa176470> (NoMethodError)",
        error_backtrace: ["/var/lib/jenkins/home/jobs/houston/workspace/test/unit/git_adapter_test.rb:8:in `block in <class:GitAdapterTest>'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:1058:in `run'", "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit/testcase.rb:17:in `run'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:36:in `block in run'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:425:in `_run__300096475__setup__29189092__callbacks'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:405:in `__run_callback'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:385:in `_run_setup_callbacks'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:81:in `run_callbacks'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:35:in `run'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:175:in `run_test'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:102:in `_run_test'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:93:in `block in _run_suite'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `each'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `_run_suite'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `block in _run_suites'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `map'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `_run_suites'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:75:in `_run_anything'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:964:in `run_tests'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:951:in `block in _run'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `each'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `_run'", "/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:939:in `run'", "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:21:in `run'", "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:326:in `block (2 levels) in autorun'", "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:27:in `run_once'", "/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:325:in `block in autorun'"]
      }, {
        suite: "GitAdapterTest", name: "#git dir should return the .git subdirectory when the repo is not bare",
        status: :pass, duration: 0.9480, age: 0
      }],
      coverage:     [{
        filename: "app/presenters/release_presenter.rb",
        coverage: [1, nil, 1, 0, nil, nil, 1, 0, 0, nil, 0, nil, nil, nil, 1, nil, 0, nil, nil, nil]
      }, {
        filename: "app/presenters/tester_presenter.rb",
        coverage: [1, nil, 1, 0, nil, nil, 1, 0, nil, nil, 0, nil, nil, nil, nil]
      }, {
        filename: "app/presenters/testing_note_presenter.rb",
        coverage: [1, 1, nil, 1, 0, nil, nil, 1, 0, 0, nil, 0, nil, nil, nil, 1, nil, nil, nil, nil, nil, nil, 0, nil, nil, nil]
      }, {
        filename: "app/presenters/ticket_presenter.rb",
        coverage: [1, 1, 1, nil, 1, nil, 1, 0, nil, nil, 1, 0, 0, nil, 0, nil, nil, nil, nil, nil, 1, 0, nil, nil, 1, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0, nil, nil, nil, 1, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0, nil, nil, nil, nil]
      }],
      covered_percent: 0.4877472689695896,
      covered_strength: 0.007832890463537053
    }

    project = Project.new
    jenkins = Houston::Adapters::CIServer::JenkinsAdapter::Job.new(project)

    mock(jenkins.connection).get(result_url) do |url|
      OpenStruct.new(status: 200, body: result_response)
    end

    mock(jenkins.connection).get(test_report_url) do |url|
      OpenStruct.new(status: 200, body: test_report_response)
    end

    mock(jenkins.connection).get(coverage_report_url) do |url|
      OpenStruct.new(status: 200, body: coverage_report_response)
    end

    actual_results = jenkins.fetch_results!(build_url)
    assert_deep_equal expected_results, actual_results
  end


private


  def result_response
    '{"result":"FAILURE"}'
  end

  def test_report_response
    <<-JSON
    {
      "duration": 0.8849784,
      "failCount": 1,
      "passCount": 3,
      "skipCount": 0,
      "suites": [{
        "cases": [{
          "age": 0,
          "className": "ChangeTest",
          "duration": 0.001334,
          "errorDetails": null,
          "errorStackTrace": null,
          "failedSince": 0,
          "name": "test_should_have_a_tag_when_created_for_a_slug_that_has_been_aliased_to_a_tag",
          "skipped": false,
          "status": "PASSED",
          "stderr": "\\n  ",
          "stdout": "\\n  "
        }, {
          "age": 0,
          "className": "ChangeTest",
          "duration": 9.964E-4,
          "errorDetails": null,
          "errorStackTrace": null,
          "failedSince": 0,
          "name": "test_should_have_a_tag_when_created_for_a_slug_that_has_been_associated_with_a_tag",
          "skipped": false,
          "status": "PASSED",
          "stderr": "\\n  ",
          "stdout": "\\n  "
        }],
        "duration": 0.0324833,
        "id": null,
        "name": "ChangeTest",
        "stderr": "\\n  ",
        "stdout": "\\n  ",
        "timestamp": null
      }, {
        "cases": [{
          "age": 13,
          "className": "GitAdapterTest",
          "duration": 0.0019763,
          "errorDetails": "undefined method `git_dir' for #<Houston::Adapters::VersionControl::NullRepoClass:0xa176470>",
          "errorStackTrace": "\\nundefined method `git_dir' for #<Houston::Adapters::VersionControl::NullRepoClass:0xa176470> (NoMethodError)\\n/var/lib/jenkins/home/jobs/houston/workspace/test/unit/git_adapter_test.rb:8:in `block in <class:GitAdapterTest>'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:1058:in `run'\\n/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit/testcase.rb:17:in `run'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:36:in `block in run'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:425:in `_run__300096475__setup__29189092__callbacks'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:405:in `__run_callback'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:385:in `_run_setup_callbacks'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/callbacks.rb:81:in `run_callbacks'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/activesupport-3.2.9/lib/active_support/testing/setup_and_teardown.rb:35:in `run'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:175:in `run_test'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:102:in `_run_test'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:93:in `block in _run_suite'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `each'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:92:in `_run_suite'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `block in _run_suites'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `map'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:83:in `_run_suites'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/ci_reporter-1.8.3/lib/ci/reporter/minitest.rb:75:in `_run_anything'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:964:in `run_tests'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:951:in `block in _run'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `each'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:950:in `_run'\\n/var/lib/jenkins/.rvm/gems/ruby-1.9.3-p327/gems/minitest-3.2.0/lib/minitest/unit.rb:939:in `run'\\n/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:21:in `run'\\n/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:326:in `block (2 levels) in autorun'\\n/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:27:in `run_once'\\n/var/lib/jenkins/.rvm/rubies/ruby-1.9.3-p327/lib/ruby/1.9.1/test/unit.rb:325:in `block in autorun'    ",
          "failedSince": 6,
          "name": "test_#git_dir_should_return_path_when_the_repo_is_bare",
          "skipped": false,
          "status": "FAILED",
          "stderr": "\\n  ",
          "stdout": "\\n  "
        }, {
          "age": 0,
          "className": "GitAdapterTest",
          "duration": 9.48E-4,
          "errorDetails": null,
          "errorStackTrace": null,
          "failedSince": 0,
          "name": "test_#git_dir_should_return_the_.git_subdirectory_when_the_repo_is_not_bare",
          "skipped": false,
          "status": "PASSED",
          "stderr": "\\n  ",
          "stdout": "\\n  "
        }],
        "duration": 0.0029243,
        "id": null,
        "name": "GitAdapterTest",
        "stderr": "\\n  ",
        "stdout": "\\n  ",
        "timestamp": null
      }]
    }
    JSON
  end

  def coverage_report_response
    <<-JSON
    {
      "timestamp": 1363652897,
      "command_name": "Functional Tests",
      "files": [{
        "filename": "/var/lib/jenkins/home/jobs/houston/workspace/app/presenters/release_presenter.rb",
        "coverage": [1, null, 1, 0, null, null, 1, 0, 0, null, 0, null, null, null, 1, null, 0, null, null, null]
      }, {
        "filename": "/var/lib/jenkins/home/jobs/houston/workspace/app/presenters/tester_presenter.rb",
        "coverage": [1, null, 1, 0, null, null, 1, 0, null, null, 0, null, null, null, null]
      }, {
        "filename": "/var/lib/jenkins/home/jobs/houston/workspace/app/presenters/testing_note_presenter.rb",
        "coverage": [1, 1, null, 1, 0, null, null, 1, 0, 0, null, 0, null, null, null, 1, null, null, null, null, null, null, 0, null, null, null]
      }, {
        "filename": "/var/lib/jenkins/home/jobs/houston/workspace/app/presenters/ticket_presenter.rb",
        "coverage": [1, 1, 1, null, 1, null, 1, 0, null, null, 1, 0, 0, null, 0, null, null, null, null, null, 1, 0, null, null, 1, 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, 1, 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null]
      }],
      "metrics": {
        "covered_percent": 48.77472689695896,
        "covered_strength": 0.7832890463537053,
        "covered_lines": 1652,
        "total_lines": 3387
      }
    }
    JSON
  end


end
