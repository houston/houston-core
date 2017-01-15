require "houston/adapters/version_control/null_repo"

module Houston
  module Adapters
    module VersionControl
      class NoneAdapter

        def self.errors_with_parameters(*args)
          {}
        end

        def self.build(*args)
          Houston::Adapters::VersionControl::NullRepo
        end

        def self.parameters
          []
        end

      end
    end
  end
end
