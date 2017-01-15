require "houston/adapters/ticket_tracker/null_connection"

module Houston
  module Adapters
    module TicketTracker
      class NoneAdapter

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
