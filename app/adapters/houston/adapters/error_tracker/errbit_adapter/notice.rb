module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        class Notice

          def initialize(attributes={})
            @attributes = attributes
          end

          attr_reader :attributes


          def created_at
            attributes[:created_at]
          end

          def app_id
            attributes[:app_id]
          end

        end
      end
    end
  end
end
