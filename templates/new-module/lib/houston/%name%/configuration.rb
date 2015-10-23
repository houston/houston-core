module Houston::<%= camelized %>
  class Configuration

    def initialize
      config = Houston.config.module(:<%= name %>).config
      instance_eval(&config) if config
    end

    # Define configuration DSL here

  end
end
