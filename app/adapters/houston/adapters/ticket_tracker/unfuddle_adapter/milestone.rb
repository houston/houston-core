module Houston
  module Adapters
    module TicketTracker
      class UnfuddleAdapter
        class Milestone
          
          
          def initialize(connection, attributes)
            @connection       = connection
            @raw_attributes   = attributes
            @remote_id        = attributes["id"]
            @name             = attributes["title"]
          end
          
          attr_reader :raw_attributes,
                      :remote_id,
                      :name
          
          def attributes
            { remote_id:      remote_id,
              name:           name }
          end
          
          
        end
      end
    end
  end
end
