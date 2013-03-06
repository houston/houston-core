module Houston
  module CI
    module Adapter
      class JenkinsAdapter
        class Job
          
          def initialize(project)
            @project = project
            
            config = Houston.config.ci_server_configuration
            @connection = Faraday.new(url: "https://" << config[:host])
            @connection.basic_auth config[:username], config[:password] if config[:username] && config[:password]
          end
          
          attr_reader :project, :connection
          
          
          
          def build!(commit)
            url = build_path(commit)
            Rails.logger.info "[jenkins] POST #{url}"
            response = connection.post(url)
            unless [200, 201, 302].member?(response.status)
              raise Houston::CI::Error.new("Houston was unable to trigger a build for #{project.name} with the URL #{url}.")
            end
          end
          
          def fetch_results!(build_url)
            result_url = "#{build_url}/api/json?tree=result"
            test_report_url = "#{build_url}/testReport/api/json"
            
            results = {}
            
            Rails.logger.debug "[jenkins] GET #{result_url}"
            response = connection.get(result_url)
            raise Houston::CI::Error, "Houston could not get the result of the build from the URL #{result_url}" unless response.status == 200
            response = JSON.parse(response.body)
            
            results[:result] = translate_result(response["result"])
            
            Rails.logger.debug "[jenkins] GET #{test_report_url}"
            response = connection.get(test_report_url)
            raise Houston::CI::Error, "Houston could not get detailed test results from the URL #{test_report_url}. Most likely the build failed before the tests could be run." unless response.status == 200
            response = JSON.parse(response.body)
            
            tests = translate_suites(response["suites"])
            results[:duration] = translate_duration(response["duration"])
            results[:total_count] = tests.count
            results[:fail_count] = response["failCount"]
            results[:pass_count] = response["passCount"]
            results[:skip_count] = response["skipCount"]
            results[:tests] = tests
            
            return results
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
          
          
          
          def job_path
            "/job/#{project.slug}"
          end
          
          def build_path(commit)
            callback_url = Houston::CI.post_build_callback_url(project)
            "#{job_path}/buildWithParameters?COMMIT_SHA=#{commit}&CALLBACK_URL=#{callback_url}"
          end
          
        end
      end
    end
  end
end
