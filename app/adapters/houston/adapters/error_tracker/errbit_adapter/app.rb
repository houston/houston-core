module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        class App
          
          def initialize(connection, app_id)
            @connection = connection
            @app_id = app_id
          end
          
          attr_reader :connection, :app_id
          
          
          def project_url
            connection.project_url(app_id)
          end
          
          def error_url(err)
            connection.error_url(app_id, err)
          end
          
          
          def problems_during(range)
            connection.problems_during(range, app_id: app_id)
          end
          
          def open_problems
            connection.open_problems(app_id: app_id)
          end
          
          def resolve!(problem_id)
            connection.resolve!(problem_id)
          end
          
          def unresolve!(problem_id)
            connection.unresolve!(problem_id)
          end
          
          
          delegate :merge_problems, :unmerge_problems, :delete_problems, to: :connection
          
          
        end
      end
    end
  end
end
