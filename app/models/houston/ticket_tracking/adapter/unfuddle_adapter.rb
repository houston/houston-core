module Houston
  module TicketTracking
    module Adapter
      class UnfuddleAdapter
        
        class << self
          
          def problems_with_project_id(project_id)
            return ["cannot be blank"] if project_id.blank?
            return ["must be a number"] unless project_id.to_s =~ /\d+/
            begin
              new_connection(project_id).fetch!
            rescue Unfuddle::UnauthorizedError
              return ["is not a project that you have permission to access"]
            rescue Unfuddle::InvalidResponseError => e
              return ["is not a valid project"] if e.response.status == 404
              raise $!
            end
            []
          end
          
          def create_connection(project_id)
            return Houston::TicketTracking::NullConnection if project_id.blank?
            
            self::Connection.new new_connection(project_id)
          end
          
        private
          
          def new_connection(project_id)
            ::Unfuddle.instance.project(project_id)
          end
          
        end
        
      end
    end
  end
end
