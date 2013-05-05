module Houston
  module Adapters
    module CIServer
      class JenkinsAdapter
        class Job
          
          def initialize(project)
            @project = project
            
            config = Houston.config.ci_server_configuration(:jenkins)
            @connection = Faraday.new(url: "https://" << config[:host], ssl: {verify: false})
            @connection.basic_auth config[:username], config[:password] if config[:username] && config[:password]
          end
          
          attr_reader :project, :connection
          
          def job_url
            "#{@connection.url_prefix}#{job_path}"
          end
          
          
          
          def build!(commit)
            url = build_path(commit)
            Rails.logger.info "[jenkins] POST #{url}"
            response = connection.post(url)
            unless [200, 201, 302].member?(response.status)
              raise Houston::Adapters::CIServer::Error.new("Houston was unable to trigger a build for #{project.name} with the URL #{url}.")
            end
          end
          
          def fetch_results!(build_url)
            result_url = "#{build_url}/api/json?tree=result"
            test_report_url = "#{build_url}/testReport/api/json"
            coverage_report_url = "#{build_url}/artifact/coverage/coverage.json"
            
            
            response = fetch_json(result_url, resource_name: "the result of the build")
            results = {result: translate_result(response["result"])}
            
            
            response = fetch_json(test_report_url, resource_name: "detailed test results",
              additional_error_info: "Most likely the build failed before the tests could be run.")
            tests = translate_suites(response["suites"])
            results[:duration] = translate_duration(response["duration"])
            results[:total_count] = tests.count
            results[:fail_count] = response["failCount"]
            results[:pass_count] = response["passCount"]
            results[:skip_count] = response["skipCount"]
            results[:tests] = tests
            
            
            response = fetch_json(coverage_report_url, resource_name: "coverage report", fallback_value: {})
            metrics = response["metrics"] || {}
            results[:coverage] = translate_file_coverage(response["files"])
            results[:covered_percent] = metrics["covered_percent"] / 100.0      if metrics.key?("covered_percent")
            results[:covered_strength] = metrics["covered_strength"] / 100.0    if metrics.key?("covered_strength")
            
            results
          end
          
          def fetch_json(url, options)
            resource = options.fetch(:resource_name, "the resource")
            
            Rails.logger.debug "[jenkins] GET #{url}"
            response = connection.get(url)
            unless response.status == 200
              return options[:fallback_value] if options.key?(:fallback_value)
              
              error_message = "Houston could not get #{resource} from the URL #{url.inspect}."
              error_message << " " << options[:additional_error_info] if options.key?(:additional_error_info)
              raise Houston::Adapters::CIServer::Error, error_message
            end
            
            JSON.parse(response.body)
            
          rescue JSON::ParserError
            error_message = "Houston could not parse #{resource} from the URL #{url.inspect}."
            error_message << " [#{$!.message}]"
            error_message << " " << options[:additional_error_info] if options.key?(:additional_error_info)
            raise Houston::Adapters::CIServer::Error, error_message
          end
            
          
          
          
          def translate_result(result)
            { "FAILURE" => :fail,
              "UNSTABLE" => :fail,
              "SUCCESS" => :pass }[result] ||
              (raise NotImplementedError.new("#{result} is not a mapped result from Jenkins"))
          end
          
          def translate_duration(seconds)
            seconds * 1000 # milliseconds!
          end
          
          def translate_suites(suites)
            tests = []
            suites.each do |suite|
              suite_name = suite["name"]
              suite["cases"].each do |test_case|
                test = {
                  suite: suite_name,
                  name:  translate_test_name(test_case["name"])
                }
                
                if test_case["skipped"]
                  test[:status]   = :skip
                else
                  test[:status]   = translate_status(test_case["status"])
                  test[:duration] = translate_duration(test_case["duration"])
                  test[:age]      = test_case["age"]
                  
                  error_message, error_backtrace = translate_stack_trace(test_case["errorStackTrace"])
                  if error_message
                    # test[:status] = :error # <-- until we can differentiate errors and fails, call them fails
                    test[:error_message] = error_message
                    test[:error_backtrace] = error_backtrace
                  end
                end
                
                tests << test
              end
            end
            tests
          end
          
          def translate_test_name(name)
            name.gsub(/^test_/, "").gsub("_", " ")
          end
          
          def translate_status(status)
            { "FAILED" => :fail,
              "REGRESSION" => :fail,
              "PASSED" => :pass,
              "FIXED"  => :pass }[status] ||
              (raise NotImplementedError.new("#{status} is not a mapped status from Jenkins"))
          end
          
          def translate_stack_trace(stack_trace)
            lines = stack_trace.to_s.split("\n").map(&:strip).reject(&:blank?)
            message = lines[0]
            backtrace = lines[1..-1]
            [message, backtrace]
          end
          
          
          
          def translate_file_coverage(files)
            Array.wrap(files).map do |file|
              { filename: get_relative_filename(file["filename"]),
                coverage: file["coverage"] }
            end
          end
          
          # Gets the path of the file in question relative to the
          # project's root directory.
          #
          # Works by assuming that the project has been checked out
          # to a folder named "workspace" by Jenkins: a reasonable
          # assumption, but not probably the most robust way of
          # implementing this!
          WORKSPACE_MATCHER = /(?<=\/workspace\/).*/
          def get_relative_filename(filename)
            filename[WORKSPACE_MATCHER] || filename
          end
          
          
          
          def job_path
            "/job/#{project.slug}"
          end
          
          def build_path(commit)
            callback_url = Houston::Adapters::CIServer.post_build_callback_url(project)
            "#{job_path}/buildWithParameters?COMMIT_SHA=#{commit}&CALLBACK_URL=#{callback_url}"
          end
          
        end
      end
    end
  end
end
