require "support/houston/adapters/ci_server/mock_adapter/job"

module Houston
  module Adapters
    module CIServer
      class MockAdapter

        def self.errors_with_parameters(project)
          {}
        end

        def self.build(project)
          Job.new(project)
        end

        def self.parameters
          []
        end

      end
    end
  end
end
