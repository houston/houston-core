module Houston
  module CI
    module Adapter
      class MockAdapter
        class Job
          
          def initialize(project)
            @project = project
          end
          
          def build!(commit)
          end
          
          def fetch_results!(results_url)
            {}
          end
          
        end
      end
    end
  end
end
