module Houston
  module ErrorTracker
    module Adapter
      class ErrbitAdapter
        class Notice
          
          def initialize(attributes={})
            @attributes = attributes
          end
          
          attr_reader :attributes
          
          
          def created_at
            attributes[:created_at]
          end
          
        end
      end
    end
  end
end
