module Houston
  module Adapters
    module TicketTracker
      class UnfuddleAdapter
        class Ticket



          def initialize(connection, attributes)
            @connection       = connection
            @raw_attributes   = attributes
            @severity         = get_severity_name(attributes["severity_id"]) if attributes["severity_id"]
            @component        = get_component_name(attributes["component_id"]) if attributes["component_id"]

            # required
            @remote_id        = attributes["id"]
            @number           = attributes["number"]
            @summary          = attributes["summary"]
            @description      = attributes["description"]
            @reporter_email   = attributes["reporter_email"]
            @milestone_id     = attributes["milestone_id"]
            @type             = get_type
            @created_at       = Time.parse(attributes["created_at"]) if attributes["created_at"]
            @closed_at        = Time.parse(attributes["closed_on"]) if attributes["closed_on"]

            # optional
            @tags             = get_tags
            @due_date         = attributes["due_on"]
          end

          attr_reader :raw_attributes,

                      :remote_id,
                      :number,
                      :summary,
                      :description,
                      :reporter_email,
                      :milestone_id,
                      :type,
                      :created_at,
                      :closed_at,

                      :tags,
                      :severity,
                      :component,
                      :due_date

          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              reporter_email: reporter_email,
              milestone_id:   milestone_id,
              type:           type,
              created_at:     created_at,
              closed_at:      closed_at,

              tags:           tags,
              due_date:       due_date }
          end



          def resolve!
            unless %w{resolved closed}.member? @raw_attributes["status"].to_s.downcase
              Houston.benchmark title: "Resolve Unfuddle Ticket" do
                ticket = unfuddle.ticket(remote_id)
                ticket.update_attributes!("status" => "Resolved", "resolution" => "fixed")
              end
            end
          end

          def close!
            Houston.benchmark title: "Close Unfuddle Ticket" do
              ticket = unfuddle.ticket(remote_id)
              ticket.update_attributes!("status" => "closed")
            end
          end

          def reopen!
            unless %w{closed}.member? @raw_attributes["status"].to_s.downcase
              Houston.benchmark title: "Reopen Unfuddle Ticket" do
                ticket = unfuddle.ticket(remote_id)
                ticket.update_attributes!("status" => "Reopened", "resolution" => "")
              end
            end
          end



          def set_milestone!(milestone_id)
            Houston.benchmark title: "Update Unfuddle Ticket" do
              ticket = unfuddle.ticket(remote_id)
              ticket.update_attribute("milestone_id", milestone_id || 0)
            end
          end



          def create_comment!(comment)
            Houston.benchmark title: "Create Unfuddle Comment" do
              unfuddle.as_user(comment.user) do
                ticket = unfuddle.ticket(remote_id)
                ticket.create_comment("body" => comment.body).id
              end
            end
          end

          def update_comment!(comment)
            Houston.benchmark title: "Update Unfuddle Comment" do
              unfuddle.as_user(comment.user) do
                unfuddle_comment = comment(comment.remote_id)
                return unless unfuddle_comment

                unfuddle_comment.project_id = unfuddle.project_id
                unfuddle_comment.update_attributes!("body" => comment.body)
              end
            end
          end

          def destroy_comment!(comment)
            Houston.benchmark title: "Destroy Unfuddle Comment" do
              unfuddle_comment = comment(comment.remote_id)
              return unless unfuddle_comment

              unfuddle_comment.project_id = unfuddle.project_id
              unfuddle_comment.destroy!
            end
          end



          def get_custom_value(custom_field_name)
            unfuddle_ticket = @raw_attributes

            retried_once = false
            begin
              custom_field_key = custom_field_name.underscore.gsub(/\s/, "_")

              key = find_in_cache_or_execute(custom_field_key(custom_field_key)) do
                connection.get_ticket_attribute_for_custom_value_named!(custom_field_name) rescue "undefined"
              end

              value_id = unfuddle_ticket[key]
              return nil if value_id.blank?
              find_in_cache_or_execute(custom_value_key(custom_field_key, value_id)) do
                connection.find_custom_field_value_by_id!(custom_field_name, value_id).value
              end
            rescue
              if retried_once
                raise
              else

                # If an error occurred above, it may be because
                # we cached the wrong value for something.
                retried_once = true
                connection.invalidate_cache!("#{custom_field_key}_field", "#{custom_field_key}_value_#{value_id}")
                retry
              end
            end
          end



        private

          attr_reader :connection
          alias :unfuddle :connection

          delegate :find_in_cache_or_execute,
                   :invalidate_cache,
                   :project_id,
                   :to => :connection



          def get_type
            identify_type_proc = unfuddle.config[:identify_type]
            identify_type_proc.call(self) if identify_type_proc
          end

          def get_tags
            identify_tags_proc = unfuddle.config[:identify_tags]
            return [] unless identify_tags_proc
            identify_tags_proc.call(self)
          end



          def get_severity_name(severity_id)
            severity = unfuddle.severities.find { |severity| severity.id == severity_id }
            severity && severity.name
          end

          def get_component_name(component_id)
            component = unfuddle.components.find { |component| component.id == component_id }
            component && component.name
          end



          def comment(remote_comment_id)
            return nil unless remote_comment_id

            ticket = unfuddle.ticket(remote_id)
            ticket.comment(remote_comment_id)
          end



          def custom_field_key(custom_field_key)
            "unfuddle/projects/#{project_id}/custom_field/#{custom_field_key}/name"
          end

          def custom_value_key(custom_field_key, value_id)
            "unfuddle/projects/#{project_id}/custom_field/#{custom_field_key}/value/#{value_id}"
          end



        end
      end
    end
  end
end
