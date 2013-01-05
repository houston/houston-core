module Houston
  module CI
    module Adapter
      class NoneAdapter
        
        def self.job_for_project(project)
          Job.new(project)
        end
        
      end
    end
  end
end
