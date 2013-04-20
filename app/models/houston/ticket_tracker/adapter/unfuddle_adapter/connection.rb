require_dependency "houston/ticket_tracker/adapter/unfuddle_adapter/ticket"

module Houston
  module TicketTracker
    module Adapter
      class UnfuddleAdapter
        class Connection
          
          def initialize(unfuddle)
            @unfuddle = unfuddle
            @project_id = unfuddle.id
          end
          
          attr_reader :project_id
          
          delegate :get_ticket_attribute_for_custom_value_named!,
                   :find_custom_field_value_by_id!,
                   :find_custom_field_value_by_value!,
                   :ticket,
                   :severities,
                   :to => :unfuddle
          
          
          
          def build_ticket(attributes)
            Houston::TicketTracker::Adapter::UnfuddleAdapter::Ticket.new(self, attributes)
          end
          
          def find_ticket(ticket_id)
            attributes = unfuddle.find_ticket(ticket_id) unless ticket_id.blank?
            build_ticket(attributes) if attributes
          end
          
          def find_tickets!(*args)
            query = find_in_cache_or_execute(query_key(args)) { construct_ticket_query(*args) }
            remote_tickets = unfuddle.find_tickets!(*query)
            remote_tickets.map { |attributes | build_ticket(attributes) }
          rescue Unfuddle::ConnectionError
            raise Houston::TicketTracker::ConnectionError.new($!)
          rescue Unfuddle::Error
            raise Houston::TicketTracker::PassThroughError.new($!)
          end
          
          
          
          def project_url
            "https://#{Unfuddle.instance.subdomain}.unfuddle.com/a#/projects/#{project_id}"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/tickets/by_number/#{ticket_number}"
          end
          
          
          
          def construct_ticket_query(*args)
            unfuddle.construct_ticket_query(*args)
          rescue Unfuddle::UndefinedCustomField, Unfuddle::UndefinedCustomFieldValue, Unfuddle::UndefinedSeverity
            raise Houston::TicketTracker::InvalidQueryError.new($!)
          end
          
          
          
          def query_key(query)
            "query/#{Digest::MD5::hexdigest(query.inspect)}"
          end
          
          def find_in_cache_or_execute(key, &block)
            Rails.cache.fetch(cache_key(key), &block)
          end
          
          def invalidate_cache!(*keys)
            keys.each do |key|
              Rails.cache.delete cache_key(key)
            end
          end
          
          def cache_key(key)
            "unfuddle/projects/#{project_id}/#{key}"
          end
          
          
          
        private
          
          attr_reader :unfuddle
          
        end
      end
    end
  end
end
