module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        
        class << self
          
          def errors_with_parameters(project, app_id)
            return {errbit_app_id: ["cannot be blank"]} if app_id.blank?
            
            # !todo: validate that the app exists
            # begin
            #   new_app(app_id).fetch!
            # rescue
            #   binding.pry
            # end
            
            {}
          end
          
          def build(project, app_id)
            return Houston::Adapters::ErrorTracker::NullApp if app_id.blank?
            new_app(app_id)
          end
          
          def parameters
            [:errbit_app_id]
          end
          
          
          
          def connection
            @connection ||= self::Connection.new
          end
          
          def open_problems(*args)
            connection.open_problems(*args)
          end
          
          def all_problems(*args)
            connection.all_problems(*args)
          end
          
          def problems_during(*args)
            connection.problems_during(*args)
          end
          
          def notices_during(*args)
            connection.notices_during(*args)
          end
          
          
          
        private
          
          def new_app(project_id)
            self::App.new(connection, project_id)
          end
          
        end
        
      end
    end
  end
end
