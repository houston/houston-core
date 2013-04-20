module Houston
  module ErrorTracker
    module Adapter
      class ErrbitAdapter
        class App
          
          def initialize(connection, app_id)
            @connection = connection
            @app_id = app_id
          end
          
          attr_reader :connection, :app_id
          
          
          def project_url
            @project_url ||= begin
              protocol = Houston.config.errbit[:port] == 443 ? "https" : "http"
              host = Houston.config.errbit[:host]
              "#{protocol}://#{host}/apps/#{app_id}"
            end
          end
          
          def error_url(err)
            "#{project_url}/errs/#{err}"
          end
          
          
        end
      end
    end
  end
end
