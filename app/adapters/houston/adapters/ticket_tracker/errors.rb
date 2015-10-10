module Houston
  module Adapters
    module TicketTracker

      class Error < StandardError
        def initialize(original_error)
          @original_error = original_error
          super(original_error.message)
          set_backtrace(original_error.backtrace)
        end

        attr_reader :original_error
      end

      class ConnectionError < Error
      end

      class InvalidQueryError < Error
      end

    end
  end
end
