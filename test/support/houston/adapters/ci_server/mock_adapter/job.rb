module Houston
  module Adapters
    module CIServer
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

          def last_build_url
            "/test"
          end

        end
      end
    end
  end
end
