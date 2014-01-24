require_dependency "houston/adapters/ticket_tracker/unfuddle_adapter/ticket"
require_dependency "houston/adapters/ticket_tracker/unfuddle_adapter/milestone"

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
          
          def create_ticket!(houston_ticket)
            as_user(houston_ticket.reporter) do
              attrs = get_attributes_from_type(houston_ticket.type)
              
              native_ticket = unfuddle.create_ticket(
                "project_id" => project_id, # required for fetch! to work below
                "priority" => "3", # required by Unfuddle
                "summary" => houston_ticket.summary,
                "description" => houston_ticket.description,
                "severity_id" => attrs[:severity] && unfuddle.find_severity_by_name!(attrs[:severity]).id)
              native_ticket.fetch! # fetch attributes we don't know yet (like number and created_at)
              
              build_ticket(native_ticket.attributes)
            end
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
          
          def all_tickets
            Unfuddle.with_config(timeout: 300) do
              find_tickets!
            end
          end
          
          def open_tickets
            Unfuddle.with_config(timeout: 300) do
              find_tickets!(status: neq(:closed), resolution: 0)
            end
          end
          
          def project_url
            "https://#{Unfuddle.instance.subdomain}.unfuddle.com/a#/projects/#{project_id}"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/tickets/by_number/#{ticket_number}"
          end
          
          
          
          def all_milestones
            unfuddle.milestones
              .reject { |m| m.archived }
              .map { |attributes | build_milestone(attributes) }
          end
          
          def open_milestones
            unfuddle.milestones
              .reject { |m| m.completed || m.archived }
              .map { |attributes | build_milestone(attributes) }
          end
          
          
          
          # Optional API
          
          def build_milestone(attributes)
            attributes = attributes.attributes if attributes.is_a?(Unfuddle::Milestone)
            Houston::Adapters::TicketTracker::UnfuddleAdapter::Milestone.new(self, attributes)
          end
          
          def create_milestone!(houston_milestone)
            native_milestone = unfuddle.create_milestone(
              "project_id" => project_id, # required for fetch! to work below
              "title" => houston_milestone.name)
            native_milestone.fetch! # fetch attributes we don't know yet
            
            build_milestone(native_milestone)
          end
          
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
          
          
          
          def as_user(user, &block)
            credentials = user.credentials.for("Unfuddle")
            login, password = credentials.login, credentials.password.decrypt(Houston.config.passphrase)
            Unfuddle.with_config(username: login, password: password, &block)
          rescue Unfuddle::ConfigurationError
            raise UserCredentials::MissingCredentials
          rescue Unfuddle::UnauthorizedError
            raise UserCredentials::InvalidCredentials if !credentials.valid?
            raise UserCredentials::InsufficientPermissions, "You do not have permission in Unfuddle to perform this action."
          end
          
          
          
          def deployment_field
            @deployment_field ||= unfuddle. \
              get_ticket_attribute_for_custom_value_named!(Houston::TMI::NAME_OF_DEPLOYMENT_FIELD)
          end
          
          
          
        private
          
          attr_reader :unfuddle
          
          def get_attributes_from_type(type)
            attributes_from_type_proc = config[:attributes_from_type]
            return {} unless attributes_from_type_proc
            attributes_from_type_proc.call(type)
          end
          
        end
      end
    end
  end
end
