require "support/houston/ci/adapter/mock_adapter/job"

module Houston
  module CI
    module Adapter
      class MockAdapter
        
        def self.job_for_project(project)
          Job.new(project)
        end
        
      end
    end
  end
end
