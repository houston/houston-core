module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        class Connection
          
          def initialize
            @config = Houston.config.error_tracker_configuration(:errbit)
            raise Houston::MissingConfiguration, "Houston is missing configuration for Errbit" unless config
            
            protocol = config[:port] == 443 ? "https" : "http"
            @errbit_url = "#{protocol}://#{config[:host]}"
            @connection = Faraday.new(url: errbit_url)
          end
          
          attr_reader :config, :errbit_url
          
          
          
          def problems_during(range)
            fetch_problems start_date: range.begin.strftime("%Y-%m-%d"), end_date: range.end.strftime("%Y-%m-%d")
          end
          
          def notices_during(range)
            fetch_notices start_date: range.begin.strftime("%Y-%m-%d"), end_date: range.end.strftime("%Y-%m-%d")
          end
          
          
          
        private
          
          
          
          def fetch_problems(params)
            get("api/v1/problems.json", params)
              .reject { |problem| problem["resolved"].present? && problem["resolved_at"].nil? }
              .map(&method(:to_problem))
          end
          
          def to_problem(attributes)
            Problem.new(
              first_notice_at: attributes["first_notice_at"].try(:to_time),
              resolved: attributes["resolved"],
              resolved_at: attributes["resolved_at"].try(:to_time),
              app_id: attributes["app_id"])
          end
          
          
          
          def fetch_notices(params)
            get("api/v1/notices.json", params)
              .map(&method(:to_notice))
          end
          
          def to_notice(attributes)
            Notice.new(
              created_at: attributes["created_at"].try(:to_time),
              app_id: attributes["app_id"])
          end
          
          
          
          def get(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            response = Project.benchmark("[errbit] fetch \"#{path}\" (#{params.inspect})") { @connection.get(path, params) }
            Yajl.load(response.body)
          end
          
        end
      end
    end
  end
end
