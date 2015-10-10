module Houston
  module Adapters
    module TicketTracker
      class MockAdapter

        def self.errors_with_parameters(*args)
          {}
        end

        def self.build(*args)
          Houston::Adapters::TicketTracker::NullConnection
        end

        def self.parameters
          []
        end

      end
    end
  end
end
