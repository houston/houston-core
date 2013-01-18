module Houston
  module TicketTracking
    module Adapter
      class UnfuddleAdapter
        class Connection
          
          def initialize(unfuddle)
            @unfuddle = unfuddle
            @project_id = unfuddle.id
          end
          
          attr_reader :project_id
          
          # !todo: do these belong in the public interface for a Ticket Tracking System?
          delegate :get_ticket_attribute_for_custom_value_named!,
                   :find_custom_field_value_by_id!,
                   :find_custom_field_value_by_value!,
                   :ticket,
                   :severities,
                   :to => :unfuddle
          
          
          
          def construct_ticket_query(*args)
            unfuddle.construct_ticket_query(*args)
          rescue Unfuddle::UndefinedCustomField, Unfuddle::UndefinedCustomFieldValue, Unfuddle::UndefinedSeverity
            raise Houston::TicketTracking::InvalidQueryError.new($!)
          end
          
          def find_tickets!(*args)
            unfuddle.find_tickets!(*args).map do |attributes|
              Houston::TicketTracking::Adapter::UnfuddleAdapter::Ticket.new(self, attributes)
            end
          rescue Unfuddle::Error
            raise Houston::TicketTracking::PassThroughError.new($!)
          end
          
          
          
          def project_url
            "https://#{Unfuddle.instance.subdomain}.unfuddle.com/a#/projects/#{project_id}"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/tickets/by_number/#{ticket_number}"
          end
          
          
          
        private
          
          attr_reader :unfuddle
          
        end
      end
    end
  end
end
