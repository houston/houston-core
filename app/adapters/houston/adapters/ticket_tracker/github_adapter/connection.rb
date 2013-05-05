module Houston
  module Adapters
    module TicketTracker
      class GithubAdapter
        class Connection
          
          def initialize(repo_path)
            @repo_path = repo_path
          end
          
          attr_reader :repo_path
          
          
          
          def build_ticket(attributes)
            Houston::Adapters::TicketTracker::GithubAdapter::Issue.new(self, attributes)
          end
          
          def find_ticket(ticket_id)
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
          
          
          
        private
          
          def client
            @client ||= Octokit::Client.new
          end
          
        end
      end
    end
  end
end
