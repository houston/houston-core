module Houston
  module TicketTracking
    module Adapter
      class MockAdapter
        
        def self.problems_with_project_id(*args)
          []
        end
        
        def self.create_connection(*args)
          Houston::TicketTracking::NullConnection
        end
        
      end
    end
  end
end
