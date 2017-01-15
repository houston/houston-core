require "houston/adapters/ticket_tracker/unfuddle_adapter/connection"

module Houston
  module Adapters
    module TicketTracker
      class UnfuddleAdapter

        class << self

          def errors_with_parameters(project, project_id)
            return {"unfuddle.projectId" => ["cannot be blank"]} if project_id.blank?
            return {"unfuddle.projectId" => ["must be a number"]} unless project_id.to_s =~ /\d+/
            begin
              new_connection(project_id).fetch!
            rescue Unfuddle::UnauthorizedError
              return {"unfuddle.projectId" => ["is not a project that you have permission to access"]}
            rescue Unfuddle::InvalidResponseError => e
              return {"unfuddle.projectId" => ["is not a valid project"]} if e.response.status == 404
              raise $!
            end
            {}
          end

          def build(project, project_id)
            return Houston::Adapters::TicketTracker::NullConnection if project_id.blank?

            self::Connection.new new_connection(project_id)
          end

          def parameters
            %w{unfuddle.projectId}
          end

        private

          def new_connection(project_id)
            ::Unfuddle.instance.project(project_id)
          end

        end

      end
    end
  end
end
