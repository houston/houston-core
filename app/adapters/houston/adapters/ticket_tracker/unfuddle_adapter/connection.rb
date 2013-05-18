require_dependency "houston/adapters/ticket_tracker/unfuddle_adapter/ticket"

module Houston
  module Adapters
    module TicketTracker
      class UnfuddleAdapter
        class Connection
          include Unfuddle::NeqHelper
          
          def initialize(unfuddle)
            @unfuddle = unfuddle
            @project_id = unfuddle.id
            @config = Houston.config.ticket_tracker_configuration(:unfuddle)
          end
          
          
          
          # Required API
          
          def build_ticket(attributes)
            Houston::Adapters::TicketTracker::UnfuddleAdapter::Ticket.new(self, attributes)
          end
          
          def find_ticket_by_number(number)
            attributes = unfuddle.find_ticket_by_number(number) unless number.blank?
            build_ticket(attributes) if attributes
          end
          
          def find_tickets_numbered(*numbers)
            numbers = numbers.flatten
            return [] if numbers.empty?
            find_tickets!(number: numbers)
          end
          
          def open_tickets
            find_tickets!(status: neq(:closed), resolution: 0)
          end
          
          def project_url
            "https://#{Unfuddle.instance.subdomain}.unfuddle.com/a#/projects/#{project_id}"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/tickets/by_number/#{ticket_number}"
          end
          
          
          
          # Optional API
          
          def find_tickets!(*args)
            query = find_in_cache_or_execute(query_key(args)) { construct_ticket_query(*args) }
            remote_tickets = unfuddle.find_tickets!(*query)
            remote_tickets.map { |attributes | build_ticket(attributes) }
          rescue Unfuddle::ConnectionError
            raise Houston::Adapters::TicketTracker::ConnectionError.new($!)
          rescue Unfuddle::Error
            raise Houston::Adapters::TicketTracker::PassThroughError.new($!)
          end
          
          
          
          # Idiomatic API
          
          attr_reader :project_id, :config
          
          delegate :get_ticket_attribute_for_custom_value_named!,
                   :find_custom_field_value_by_id!,
                   :find_custom_field_value_by_value!,
                   :ticket,
                   :severities,
                   :components,
                   :to => :unfuddle
          
          
          
          def construct_ticket_query(*args)
            unfuddle.construct_ticket_query(*args)
          rescue Unfuddle::UndefinedCustomField, Unfuddle::UndefinedCustomFieldValue, Unfuddle::UndefinedSeverity
            raise Houston::Adapters::TicketTracker::InvalidQueryError.new($!)
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
