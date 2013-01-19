module Houston
  module TicketTracking
    class NullConnectionClass
      
      
      # Public API for a TicketTracking adapter
      # ------------------------------------------------------------------------- #
      
      def construct_ticket_query(*args)
        nil
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
