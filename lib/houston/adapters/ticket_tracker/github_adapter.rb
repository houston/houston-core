require "houston/adapters/ticket_tracker/github_adapter/connection"
require "houston/adapters/ticket_tracker/github_adapter/issue"

module Houston
  module Adapters
    module TicketTracker
      class GithubAdapter

        class << self

          def errors_with_parameters(project, repo)
            {}
          end

          def build(project, repo)
            return Houston::TicketTracker::NullConnection if repo.blank?

            self::Connection.new(repo)
          end

          def parameters
            %w{github.repo}
          end

        end

      end
    end
  end
end
