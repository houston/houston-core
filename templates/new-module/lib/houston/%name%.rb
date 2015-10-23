require "houston/<%= name %>/engine"
require "houston/<%= name %>/configuration"

module Houston
  module <%= camelized %>
    extend self

    attr_reader :config

  end

  <%= camelized %>.instance_variable_set :@config, <%= camelized %>::Configuration.new
end
