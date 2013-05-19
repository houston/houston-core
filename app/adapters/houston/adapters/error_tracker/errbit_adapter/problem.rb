module Houston
  module Adapters
    module ErrorTracker
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
          
          def app_id
            attributes[:app_id]
          end
          
        end
      end
    end
  end
end
