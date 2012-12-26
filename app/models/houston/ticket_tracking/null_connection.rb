module Houston
  module TicketTracking
    class NullConnectionClass
      
      
      # Public API for a TicketTracking adapter
      # ------------------------------------------------------------------------- #
      
      def construct_ticket_query(*args)
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
      
      
      
      # !todo: do these belong in the public interface for a Ticket Tracking System?
      
      def find_custom_field_value_by_id!(custom_field_name, value_id)
      end
      
      def find_custom_field_value_by_value!(*args)
      end
      
      def get_ticket_attribute_for_custom_value_named!(custom_field_name)
      end
      
      # ------------------------------------------------------------------------- #
      
      
      def nil?
        true
      end
      
    end
    
    NullConnection = NullConnectionClass.new
  end
end
