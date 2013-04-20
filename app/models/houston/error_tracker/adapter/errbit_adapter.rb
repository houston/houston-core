module Houston
  module ErrorTracker
    module Adapter
      class ErrbitAdapter
        
        class << self
          
          def errors_with_parameters(project, app_id)
            return {project_id: ["cannot be blank"]} if app_id.blank?
            return {project_id: ["must be a 24-character hexadecimal number"]} unless app_id.to_s =~ /^[\da-f]{24}$/
            
            # !todo: validate that the app exists
            # begin
            #   new_app(app_id).fetch!
            # rescue
            #   binding.pry
            # end
            
            {}
          end
          
          def build(project, app_id)
            return Houston::TicketTracker::NullApp if app_id.blank?
            new_app(app_id)
          end
          
          def connection
            @connection ||= self::Connection.new
          end
          
          delegate :problems_during, :notices_during, :to => :connection
          
        private
          
          def new_app(project_id)
            self::App.new(connection, project_id)
          end
          
        end
        
      end
    end
  end
end
