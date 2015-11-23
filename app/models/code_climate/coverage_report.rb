# CodeClimate::CoverageReport
#
# Publishes code coverage information to Code Climate.
# Based on the gem 'codeclimate-test-reporter'
# which is a SimpleCov formatter that sends coverage
# results to Code Climate.
#
#  * Uses CodeClimate::TestReporter::Client from the
#    gem to publish the coverage report
#  * Generates a coverage report:
#    a JSON object structured according to the API inferred
#    from CodeClimate::TestReporter::Formatter, v0.0.7
#
# Differences from CodeClimate::TestReporter::Formatter:
#
#  * source_files/filename does not replace SimpleCov.root with '.'
#  * source_files/blob_id is read from git rather than calculated
#  * environment/pwd is absent
#  * environment/rails_root is absent
#  * environment/simplecov_root is absent
#
module CodeClimate
  module ServerError; end

  class CoverageReport

    def self.publish!(test_run)
      self.new(test_run).publish!
    end

    def initialize(test_run)
      @project = test_run.project
      @test_run = test_run
    end

    attr_reader :project, :test_run

    def publish!
      code_climate = CodeClimate::TestReporter::Client.new
      code_climate.post_results code_climate_payload
    rescue RuntimeError
      # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.8/lib/code_climate/test_reporter/client.rb#L72
      $!.extend CodeClimate::ServerError if $!.message =~ /HTTP Error: 5\d\d/
      raise
    end



    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L58-L75
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.1/lib/code_climate/test_reporter/formatter.rb#L65-L80
    def code_climate_payload
      {
        repo_token:         repo_token,
        source_files:       source_files,
        run_at:             run_at,
        covered_percent:    covered_percent,
        covered_strength:   covered_strength,
        line_counts:        line_counts,
        partial:            false,
        git:                commit_info,
        environment:        environment,
        ci_service:         ci_service
      }
    end



    def repo_token
      project.code_climate_repo_token
    end

    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L39-L56
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.1/lib/code_climate/test_reporter/formatter.rb#L51-L60
    def source_files
      @source_files ||= test_run.coverage_detail.map do |file|
        {
          name:             short_filename(file.filename),
          blob_id:          blob_id_of(file.filename),
          coverage:         file.coverage.to_json,
          covered_percent:  file.covered_percent.round(2),
          covered_strength: file.covered_strength.round(2),
          line_counts: {
            total:          file.lines.count,
            covered:        file.covered_lines.count,
            missed:         file.missed_lines.count
          }
        }
      end
    end

    def run_at
      test_run.completed_at.to_i
    end

    def covered_percent
      (100 * test_run.covered_percent).round(2)
    end

    def covered_strength
      test_run.covered_strength.round(2)
    end

    def line_counts
      @line_counts ||= source_files.each_with_object(Hash.new(0)) do |file, totals|
        totals[:total]   += file[:line_counts][:total]
        totals[:covered] += file[:line_counts][:covered]
        totals[:missed]  += file[:line_counts][:missed]
      end
    end

    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/git.rb
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.1/lib/code_climate/test_reporter/git.rb#L8-L10
    def commit_info
      {
        head:             test_run.sha,
        committed_at:     committed_at.to_i,
        branch:           test_run.branch,
      }
    end

    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L67-L73
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.1/lib/code_climate/test_reporter/formatter.rb#L74-L78
    def environment
      {
        test_framework:   "rspec",  # result.command_name.downcase
        pwd:              Dir.pwd,  # Dir.pwd
        rails_root:       nil,      # (Rails.root.to_s rescue nil)
        simplecov_root:   Dir.pwd,  # ::SimpleCov.root
        gem_version:      CodeClimate::TestReporter::VERSION
      }
    end

    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/ci.rb
    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.1/lib/code_climate/test_reporter/ci.rb#L28-L32
    def ci_service
      case project.ci_server
      when Houston::Adapters::CIServer::JenkinsAdapter::Job
        {
          name:             "jenkins",
          build_identifier: test_run.results_url[/job\/#{project.slug}\/(\d+)/, 1],
          build_url:        test_run.results_url,
          branch:           test_run.branch,
          commit_sha:       test_run.sha
        }
      else
        {}
      end
    end

    def committed_at
      # NB: CodeClimate actually uses committed_at
      return test_run.commit.authored_at if test_run.commit

      project.repo.native_commit(test_run.sha).committed_at
    rescue Houston::Adapters::VersionControl::CommitNotFound
      nil
    end



    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L85-L88
    def short_filename(filename)
      filename
    end

    # https://github.com/codeclimate/ruby-test-reporter/blob/v0.2.0/lib/code_climate/test_reporter/formatter.rb#L78-L83
    # Compare to https://github.com/codeclimate/ruby-test-reporter/blob/v0.4.8/lib/code_climate/test_reporter/calculate_blob.rb
    def blob_id_of(filename)
      blob = project.repo.find_file(filename, commit: test_run.sha)
      blob && blob.oid
    end

  end
end
