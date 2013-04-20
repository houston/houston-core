module Houston
  module TicketTracker
    module Adapter
      class NoneAdapter
        
        def self.errors_with_parameters(*args)
          {}
        end
        
        def self.build(*args)
          Houston::TicketTracker::NullConnection
        end
        
      end
    end
  end
end
