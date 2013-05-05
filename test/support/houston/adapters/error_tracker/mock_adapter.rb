module Houston
  module Adapters
    module ErrorTracker
      class MockAdapter
        
        def self.errors_with_parameters(*args)
          {}
        end
        
        def self.build(*args)
          Houston::Adapters::ErrorTracker::NullApp
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
