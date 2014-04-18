module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        class Connection
          
          def initialize
            @config = Houston.config.error_tracker_configuration(:errbit)
            raise Houston::MissingConfiguration, "Houston is missing configuration for Errbit" unless config
            
            protocol = "http"
            protocol = "https" if config[:port] == 443
            @errbit_url = "#{protocol}://#{config[:host]}"
            @errbit_url << ":#{config[:port]}" unless [80, 443].member?(config[:port])
            @connection = Faraday.new(url: errbit_url)
          end
          
          attr_reader :config, :errbit_url
          
          
          
          def problems_during(range, params={})
            fetch_problems params.merge(start_date: range.begin.iso8601, end_date: range.end.iso8601)
          end
          
          def notices_during(range, params={})
            fetch_notices params.merge(start_date: range.begin.iso8601, end_date: range.end.iso8601)
          end
          
          def open_problems(params={})
            fetch_problems params.merge(open: true)
          end
          
          def resolve!(problem_id)
            put("api/v1/problems/#{problem_id}/resolve.json")
          end
          
          def unresolve!(problem_id)
            put("api/v1/problems/#{problem_id}/unresolve.json")
          end
          
          
          
          def project_url(app_id)
            "#{errbit_url}/apps/#{app_id}"
          end
          
          def error_url(app_id, err)
            "#{project_url(app_id)}/problems/#{err}"
          end
          
          
          
        private
          
          
          
          def fetch_problems(params)
            get("api/v1/problems.json", params)
              .reject { |problem| problem["resolved"].present? && problem["resolved_at"].nil? }
              .map(&method(:to_problem))
          end
          
          def to_problem(attributes)
            ::Houston::Adapters::ErrorTracker::ErrbitAdapter::Problem.new(
              first_notice_at: attributes["first_notice_at"].try(:to_time),
              first_notice_commit: attributes["first_notice_commit"],
              first_notice_environment: attributes["first_notice_environment"],
              last_notice_at: attributes["last_notice_at"].try(:to_time),
              last_notice_commit: attributes["last_notice_commit"],
              last_notice_environment: attributes["last_notice_environment"],
              notices_count: attributes["notices_count"],
              
              resolved: attributes["resolved"],
              resolved_at: attributes["resolved_at"].try(:to_time),
              
              app_id: attributes["app_id"],
              message: attributes["message"],
              where: attributes["where"],
              environment: attributes["environment"],
              url: attributes["url"])
          end
          
          
          
          def fetch_notices(params)
            get("api/v1/notices.json", params)
              .map(&method(:to_notice))
          end
          
          def to_notice(attributes)
            attributes = attributes["notice"]
            ::Houston::Adapters::ErrorTracker::ErrbitAdapter::Notice.new(
              created_at: attributes["created_at"].try(:to_time),
              app_id: attributes["app_id"])
          end
          
          
          
          def get(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            response = Houston.benchmark("[errbit] GET \"#{path}\" (#{params.inspect})") { @connection.get(path, params) }
            MultiJson.load(response.body)
          end
          
          def put(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            response = Houston.benchmark("[errbit] PUT \"#{path}\" (#{params.inspect})") { @connection.put(path, params) }
            response.status
          end
          
        end
      end
    end
  end
end
