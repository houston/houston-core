module Houston
  module CI
    module Adapter
      class NoneAdapter
        class Job
          
          def initialize(project)
            @project = project
          end
          
          def build!(commit)
          end
          
        end
      end
    end
  end
end
