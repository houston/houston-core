module Houston
  module Adapters
    module VersionControl

      class Error < StandardError
        def initialize(original_error=nil, message=nil)
          original_error, message = nil, original_error if original_error.is_a?(String)

          if original_error
            message ||= original_error.message
            set_backtrace(original_error.backtrace)
          end

          @original_error = original_error
          @message = message
          super(message)
        end

        attr_accessor :message
        attr_reader :original_error
      end

      class CommitNotFound < Error
      end

      class BranchNotFound < Error
      end

      class FileNotFound < Error
      end

      class InvalidShaError < ArgumentError
      end

    end
  end
end
