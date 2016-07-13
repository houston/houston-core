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


  # Register events that will be raised by this module
  # register_events {{
  #   "<%= name %>:create" => params("<%= name %>").desc("<%= camelized %> was created"),
  #   "<%= name %>:update" => params("<%= name %>").desc("<%= camelized %> was updated")
  # }}

end
