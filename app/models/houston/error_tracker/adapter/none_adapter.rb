module Houston
  module ErrorTracker
    module Adapter
      class NoneAdapter
        
        def self.errors_with_parameters(*args)
          {}
        end
        
        def self.build(*args)
          Houston::ErrorTracker::NullApp
        end
        
        def self.parameters
          []
        end
        
        
        
        def self.problems_during(*args)
          []
        end
        
        def self.notices_during(*args)
          []
        end
        
      end
    end
  end
end
