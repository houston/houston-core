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


  # Extension Points
  # ===========================================================================
  #
  # Read more about extending Houston at:
  # https://github.com/houston/houston-core/wiki/Modules


  # Register events that will be raised by this module
  #
  #    register_events {{
  #      "<%= name %>:create" => params("<%= name %>").desc("<%= camelized %> was created"),
  #      "<%= name %>:update" => params("<%= name %>").desc("<%= camelized %> was updated")
  #    }}


  # Add a link to Houston's global navigation
  #
  #    add_navigation_renderer :<%= name %> do
  #      name "<%= camelized %>"
  #      path { Houston::<%= camelized %>::Engine.routes.url_helpers.<%= name %>_path }
  #      ability { |ability| ability.can? :read, Project }
  #    end


  # Add a link to feature that can be turned on for projects
  #
  #    add_project_feature :<%= name %> do
  #      name "<%= camelized %>"
  #      path { |project| Houston::<%= camelized %>::Engine.routes.url_helpers.project_<%= name %>_path(project) }
  #      ability { |ability, project| ability.can? :read, project }
  #    end

end
