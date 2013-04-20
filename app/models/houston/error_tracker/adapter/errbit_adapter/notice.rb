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
          
          def error_tracker_id
            attributes[:error_tracker_id]
          end
          
        end
      end
    end
  end
end
