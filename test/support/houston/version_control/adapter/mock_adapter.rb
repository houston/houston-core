module Houston
  module VersionControl
    module Adapter
      class MockAdapter
        
        def self.errors_with_parameters(*args)
          {}
        end
        
        def self.build(*args)
          Houston::VersionControl::NullRepo
        end
        
        def self.parameters
          []
        end
        
      end
    end
  end
end
