module Houston
  module ErrorTracker
    module Adapter
      class ErrbitAdapter
        class Problem
          
          def initialize(attributes={})
            @attributes = attributes
          end
          
          attr_reader :attributes
          
          
          def first_notice_at
            attributes[:first_notice_at]
          end
          
          def resolved_at
            attributes[:resolved_at]
          end
          
          def resolved?
            attributes[:resolved]
          end
          
          def error_tracker_id
            attributes[:error_tracker_id]
          end
          
        end
      end
    end
  end
end
