module Houston
  module Adapters
    module VersionControl
      
      class PassThroughError < StandardError
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
      
      class CommitNotFound < PassThroughError
      end
      
      class FileNotFound < PassThroughError
      end
      
      class InvalidShaError < ArgumentError
      end
      
      class CloneRepoFailed < RuntimeError
      end
      
    end
  end
end
