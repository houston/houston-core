module Houston
  module Adapters
    module CIServer
      class JenkinsAdapter

        def self.errors_with_parameters(project)
          {}
        end

        def self.build(project)
          Job.new(project)
        end

        def self.parameters
          []
        end

      end
    end
  end
end
