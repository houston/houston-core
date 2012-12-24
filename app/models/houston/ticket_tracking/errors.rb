module Houston
  module TicketTracking
    
    class PassThroughError < StandardError
      def initialize(original_error)
        @original_error = original_error
        super(original_error.message)
      end
      
      attr_reader :original_error
    end
    
    class InvalidQueryError < PassThroughError
    end
    
  end
end
