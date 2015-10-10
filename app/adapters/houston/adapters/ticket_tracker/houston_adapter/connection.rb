module Houston
  module Adapters
    module TicketTracker
      class HoustonAdapter
        class Connection
          attr_reader :project

          def initialize(project)
            @project = project
          end



          # Required API

          def features
            []
          end

          def build_ticket(attributes)
            NullTicket
          end

          def create_ticket!(ticket)
            number = project.tickets.maximum(:number).to_i + 1
            ticket.number = number
            ticket.remote_id = number
            ticket
          end

          def project_url
            "/projects/#{project.slug}"
          end

          def ticket_url(ticket_number)
            "#{project_url}/tickets/by_number/#{ticket_number}"
          end



          def find_ticket_by_number(number)
          end

        end
      end
    end
  end
end
