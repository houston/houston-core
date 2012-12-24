module Houston
  module TicketTracking
    module Adapter
      class NoneAdapter
        
        class << self
          
          def problems_with_project_id(*args)
            []
          end
          
          def create_connection(*args)
            Houston::TicketTracking::NullConnection
          end
          
          def project_url(*args)
            nil
          end
          
          def ticket_url(*args)
            nil
          end
          
        end
        
      end
    end
  end
end
