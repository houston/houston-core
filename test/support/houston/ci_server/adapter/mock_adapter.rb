require "support/houston/ci_server/adapter/mock_adapter/job"

module Houston
  module CIServer
    module Adapter
      class MockAdapter
        
        def self.errors_with_parameters(project)
          {}
        end
        
        def self.build(project)
          Job.new(project)
        end
        
      end
    end
  end
end
