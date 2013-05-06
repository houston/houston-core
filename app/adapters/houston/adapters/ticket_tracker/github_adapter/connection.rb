module Houston
  module Adapters
    module TicketTracker
      class GithubAdapter
        class Connection
          
          def initialize(repo_path)
            @repo_path = repo_path
            @config = Houston.config.ticket_tracker_configuration(:github)
          end
          
          attr_reader :repo_path, :config
          
          
          
          def build_ticket(attributes)
            Houston::Adapters::TicketTracker::GithubAdapter::Issue.new(self, attributes)
          end
          
          def find_ticket(number)
            attributes = client.issue(repo_path, number) unless number.blank?
            build_ticket(attributes) if attributes
          end
          
          def find_tickets!(options={})
            remote_issues = client.list_issues(repo_path, state: "open")
            remote_issues.map { |attributes | build_ticket(attributes) }
          end
          
          
          
          def project_url
            "https://github.com/#{repo_path}/issues"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/#{ticket_number}"
          end
          
          
          
          def client
            @client ||= Octokit::Client.new
          end
          
        end
      end
    end
  end
end
