module Houston
  module Adapters
    module TicketTracker
      class HoustonAdapter
        class << self

          def errors_with_parameters(project)
            {}
          end

          def build(project, *args)
            self::Connection.new(project)
          end

          def parameters
            []
          end

        end
      end
    end
  end
end
