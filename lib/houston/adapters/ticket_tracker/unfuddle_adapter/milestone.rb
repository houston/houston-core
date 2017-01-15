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


          def update_name!(name)
            Houston.benchmark title: "Update Unfuddle Milestone" do
              milestone = ::Unfuddle::Milestone.new(raw_attributes)
              milestone.update_attribute("title", name)
            end
          end


        private

          attr_reader :connection
          alias :unfuddle :connection

        end
      end
    end
  end
end
