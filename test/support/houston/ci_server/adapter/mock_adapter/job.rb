module Houston
  module CIServer
    module Adapter
      class MockAdapter
        class Job
          
          def initialize(project)
          end
          
          def job_url
            nil
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
