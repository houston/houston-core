module Houston
  module Adapters
    module Deployment
      class Engineyard
        class Config < EY::Config

          def initialize(config)
            @path = Struct.new(:exist?).new(true)
            @config = YAML.load(config) || {} # load_file returns `false' when the file is empty
            raise "ey.yml load error: Expected a Hash but a #{config.class.name} was returned." unless Hash === @config
            @config["environments"] ||= {}
          end

        end
      end
    end
  end
end
