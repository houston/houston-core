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
            
            @connection = Faraday.new(url: "#{errbit_url}/api/v1")
            @connection.use Faraday::RaiseErrors
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
          
          def all_problems(params={})
            fetch_problems params
          end
          
          def resolve!(problem_id, params={})
            put("problems/#{problem_id}/resolve.json", params.pick(:message))
          end
          
          def unresolve!(problem_id)
            put("problems/#{problem_id}/unresolve.json")
          end
          
          
          
          def merge_problems(problem_ids)
            post("problems/merge_several", problems: problem_ids)
          end
          
          def unmerge_problems(problem_ids)
            post("problems/unmerge_several", problems: problem_ids)
          end
          
          def delete_problems(problem_ids)
            post("problems/destroy_several", problems: problem_ids)
          end
          
          
          
          def project_url(app_id)
            "#{errbit_url}/apps/#{app_id}"
          end
          
          def error_url(app_id, err)
            "#{project_url(app_id)}/problems/#{err}"
          end
          
          
          
        private
          
          
          
          def fetch_problems(params)
            get("problems.json", params)
              .reject { |problem| problem["resolved"].present? && problem["resolved_at"].nil? }
              .map(&method(:to_problem))
          end
          
          def to_problem(attributes)
            ::Houston::Adapters::ErrorTracker::ErrbitAdapter::Problem.new(
              id: attributes["id"],
              err_ids: attributes["err_ids"],
              first_notice_at: attributes["first_notice_at"].try(:to_time),
              first_notice_commit: attributes["first_notice_commit"],
              first_notice_environment: attributes["first_notice_environment"],
              last_notice_at: attributes["last_notice_at"].try(:to_time),
              last_notice_commit: attributes["last_notice_commit"],
              last_notice_environment: attributes["last_notice_environment"],
              notices_count: attributes["notices_count"],
              
              opened_at: attributes["opened_at"].try(:to_time),
              resolved: attributes["resolved"],
              resolved_at: attributes["resolved_at"].try(:to_time),
              
              app_id: attributes["app_id"],
              message: attributes["message"],
              where: attributes["where"],
              environment: attributes["environment"],
              url: attributes["url"],
              
              comments: attributes["comments"])
          end
          
          
          
          def fetch_notices(params)
            get("notices.json", params)
              .map(&method(:to_notice))
          end
          
          def to_notice(attributes)
            ::Houston::Adapters::ErrorTracker::ErrbitAdapter::Notice.new(
              created_at: attributes["created_at"].try(:to_time),
              app_id: attributes["app_id"])
          end
          
          
          
          def get(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            response = Houston.benchmark("[errbit] GET #{path}") { @connection.get(path, params) }
            response.must_be! 200
            MultiJson.load(response.body)
          end
          
          def post(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            Houston.benchmark("[errbit] POST #{path}") { @connection.post(path, params) }
          end
          
          def put(path, params={})
            params = params.merge(auth_token: config[:auth_token])
            Houston.benchmark("[errbit] PUT #{path}") { @connection.put(path, params) }
          end
          
        end
      end
    end
  end
end
