require "houston/adapters/ticket_tracker/null_ticket"

module Houston
  module Adapters
    module TicketTracker
      class NullConnectionClass


        # Public API for a TicketTracker connection
        # ------------------------------------------------------------------------- #

        def features
          []
        end

        def build_ticket(attributes)
          NullTicket
        end

        def create_ticket!(attributes)
          raise NotImplementedError
        end

        def find_ticket_by_number(number)
          nil
        end

        def project_url
          nil
        end

        def ticket_url(ticket_number)
          nil
        end

        # ------------------------------------------------------------------------- #


        def nil?
          true
        end

      end

      NullConnection = NullConnectionClass.new
    end
  end
end
