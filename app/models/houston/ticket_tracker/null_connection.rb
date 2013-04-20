module Houston
  module TicketTracker
    class NullConnectionClass
      
      
      # Public API for a TicketTracker connection
      # ------------------------------------------------------------------------- #
      
      def build_ticket(attributes)
        NullTicket
      end
      
      def find_ticket(*args)
        nil
      end
      
      def find_tickets!(*args)
        []
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
