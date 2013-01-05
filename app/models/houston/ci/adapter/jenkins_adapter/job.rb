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
          
          def fetch_results!(results_url)
            Rails.logger.warn "[jenkins] GET #{results_url}"
            response = Faraday.get(results_url)
            
            # Assumes structure of Jenkins testReport
            results = JSON.parse(response.body)
            
            duration = results["duration"] * 1000 # convert seconds to milliseconds
            fail_count = results["failCount"]
            pass_count = results["passCount"]
            skip_count = results["skipCount"]
            details = results["suites"].each_with_index.each_with_object({}) { |(item, i), hash| hash[i.to_s] = item }
            
            result = nil
            if fail_count > 0
              result = "fail"
            elsif pass_count > 0
              result = "pass"
            end
            
            { duration: duration,
              fail_count: fail_count,
              pass_count: pass_count,
              skip_count: skip_count,
              details: details,
              result: result }
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
