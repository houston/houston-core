module Houston
  module Adapters
    module TicketTracker
      
      class PassThroughError < StandardError
        def initialize(original_error)
          @original_error = original_error
          super(original_error.message)
          set_backtrace(original_error.backtrace)
        end
        
        attr_reader :original_error
      end
      
      class ConnectionError < PassThroughError
      end
      
      class InvalidQueryError < PassThroughError
      end
      
    end
  end
end
