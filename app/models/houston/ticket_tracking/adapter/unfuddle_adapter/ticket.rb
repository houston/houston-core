require 'ostruct'

module Houston
  module TicketTracking
    module Adapter
      class UnfuddleAdapter
        class Ticket
          
          
          
          def initialize(connection, attributes)
            @connection       = connection
            
            # required
            @remote_id        = attributes["id"]
            @number           = attributes["number"]
            @summary          = attributes["summary"]
            @description      = attributes["description"]
            
            # optional
            @deployment       = get_custom_value(Houston::TMI::NAME_OF_DEPLOYMENT_FIELD, attributes)
            @goldmine         = get_custom_value(Houston::TMI::NAME_OF_GOLDMINE_FIELD, attributes)
            @prerequisites    = parse_prerequisites(attributes["associations"])
            @due_date         = attributes["due_on"]
          end
          
          attr_reader :remote_id,
                      :number,
                      :summary,
                      :description,
                      
                      :deployment,
                      :goldmine,
                      :prerequisites,
                      :due_date
          
          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              
              deployment:     deployment,
              goldmine:       goldmine,
              prerequisites:  prerequisites,
              due_date:       due_date }
          end
          
          
          
          # !todo: refactor this method to be more generic and abstract
          def update_attribute(attribute, value)
            unfuddle = connection
            
            case attribute
            when :deployment
              attribute = unfuddle.get_ticket_attribute_for_custom_value_named!(Houston::TMI::NAME_OF_DEPLOYMENT_FIELD) # e.g. field2_value_id
              id = unfuddle.find_custom_field_value_by_value!(Houston::TMI::NAME_OF_DEPLOYMENT_FIELD, value).id
              
              ticket = unfuddle.ticket(remote_id)
              ticket.update_attributes!(attribute => id)
              
            when :closed
              ticket = unfuddle.ticket(remote_id)
              ticket.update_attributes!("status" => "closed")
              
            else
              raise NotImplementedError
            end
          end
          
          
          
        private
          
          attr_reader :connection
          
          delegate :find_in_cache_or_execute,
                   :invalidate_cache,
                   :to => :connection
          
          
          
          def get_custom_value(custom_field_name, unfuddle_ticket)
            retried_once = false
            begin
              custom_field_key = custom_field_name.underscore.gsub(/\s/, "_")
              
              key = find_in_cache_or_execute("#{custom_field_key}_field") do
                connection.get_ticket_attribute_for_custom_value_named!(custom_field_name) rescue "undefined"
              end
              
              value_id = unfuddle_ticket[key]
              return nil if value_id.blank?
              find_in_cache_or_execute("#{custom_field_key}_value_#{value_id}") do
                connection.find_custom_field_value_by_id!(custom_field_name, value_id).value
              end
            rescue
              if retried_once
                raise
              else
                
                # If an error occurred above, it may be because
                # we cached the wrong value for something.
                retried_once = true
                invalidate_cache!("#{custom_field_key}_field", "#{custom_field_key}_value_#{value_id}")
                retry
              end
            end
          end
          
          
          
          def parse_prerequisites(associations)
            associations
              .select { |assocation| assocation["relationship"] == "parent" }
              .map { |assocation| assocation["ticket"]["number"] }
          end
          
          
          
        end
      end
    end
  end
end
