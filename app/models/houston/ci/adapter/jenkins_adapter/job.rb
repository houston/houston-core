module Houston
  module CI
    module Adapter
      class JenkinsAdapter
        class Job
          
          def initialize(project)
            @project = project
            @host = "http://" << Houston.config.ci_server_configuration[:host]
          end
          
          attr_reader :project, :host
          
          
          
          def build!(commit)
            url = build_url(commit)
            Rails.logger.info "[jenkins] POST #{url}"
            response = Faraday.post(url)
            if response.status == 404
              
              unless Faraday.get(host).status == 200
                raise Houston::CI::Error.new("Houston was looking for an instance of Jenkins at #{host}, but it could not find Jenkins at that URL.")
              end
              
              Rails.logger.info "[jenkins] Attempting to create a job on #{host} for #{project.slug}"
              create_job_or_fail!
              
              # Retry once
              Rails.logger.info "[jenkins] POST #{url}"
              response = Faraday.post(url)
              
              unless response.status == 200
                raise Houston::CI::Error.new("Houston attempted to create a job named \"#{project.slug}\" at #{host}, but it was unable to do so.")
              end
            end
          end
          
          def fetch_results!(build_url)
            result_url = "#{build_url}/api/json?tree=result"
            test_report_url = "#{build_url}/testReport/api/json"
            
            results = {}
            
            Rails.logger.debug "[jenkins] GET #{result_url}"
            response = Faraday.get(result_url)
            raise Houston::CI::Error unless response.status == 200
            response = JSON.parse(response.body)
            
            results[:result] = translate_result(response["result"])
            
            Rails.logger.debug "[jenkins] GET #{test_report_url}"
            response = Faraday.get(test_report_url)
            raise Houston::CI::Error unless response.status == 200
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
          
          
          
          def create_job_or_fail!
            client = Jenkins::Client.new
            client.url = host
            
            template = ERB.new(File.read(Rails.root.join("config.xml.erb")))
            git_url = project.version_control_location
            config = template.result(binding)
            
            job = Jenkins::Client::Job.new(name: project.slug, client: client)
            success = job.create!(config)
            raise Houston::CI::Error unless success
          end
          
          def job_url
            "#{host}/job/#{project.slug}"
          end
          
          def build_url(commit)
            callback_url = Houston::CI.post_build_callback_url(project)
            "#{job_url}/buildWithParameters?COMMIT_SHA=#{commit}&CALLBACK_URL=#{callback_url}"
          end
          
        end
      end
    end
  end
end
