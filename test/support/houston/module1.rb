module Houston
  module Module1
    extend self

    class Engine < ::Rails::Engine
      isolate_namespace Houston::Module1
    end

    class Configuration
      attr_accessor :option1, :option2
    end

    def config(&block)
      @configuration ||= Module1::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end
end
