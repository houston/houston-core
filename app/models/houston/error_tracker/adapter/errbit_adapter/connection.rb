module Houston
  module ErrorTracker
    module Adapter
      class ErrbitAdapter
        class Connection
          
          def initialize
            protocol = Houston.config.errbit[:port] == 443 ? "https" : "http"
            host = Houston.config.errbit[:host]
            
            @connection = Faraday.new(url: "#{protocol}://#{host}")
          end
          
          
          
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
              error_tracker_id: attributes["app_id"])
          end
          
          
          
          def fetch_notices(params)
            get("api/v1/notices.json", params)
              .map(&method(:to_notice))
          end
          
          def to_notice(attributes)
            Notice.new(created_at: attributes["created_at"].try(:to_time))
          end
          
          
          
          def get(path, params={})
            params = params.merge(auth_token: Houston.config.errbit[:auth_token])
            response = Project.benchmark("[errbit] fetch \"#{path}\" (#{params.inspect})") { @connection.get(path, params) }
            Yajl.load(response.body)
          end
          
        end
      end
    end
  end
end
