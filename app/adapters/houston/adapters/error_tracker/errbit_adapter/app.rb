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
            "#{connection.errbit_url}/apps/#{app_id}"
          end
          
          def error_url(err)
            "#{project_url}/errs/#{err}"
          end
          
          
        end
      end
    end
  end
end
