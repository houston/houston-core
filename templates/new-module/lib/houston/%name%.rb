require "houston/<%= name %>/engine"
require "houston/<%= name %>/configuration"

module Houston
  module <%= camelized %>
    extend self

    def config(&block)
      @configuration ||= <%= camelized %>::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end
end
