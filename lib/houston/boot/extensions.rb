require "houston/boot/extensions/events"
require "houston/boot/extensions/layout"
require "houston/boot/extensions/navigation"
require "houston/boot/extensions/oauth"
require "houston/boot/extensions/features"
require "houston/boot/extensions/serializers"
require "houston/boot/extensions/view"
require "houston/boot/extensions/deprecated"
require "houston/boot/serializers/active_record_serializer"
require "houston/boot/serializers/readonly_hash_serializer"


module Houston
  module Extensions
    include Houston::Extensions::Deprecated

    def events
      return @events if defined?(@events)
      @events = Houston::Extensions::Events.new
    end

    def layout
      return @layout if defined?(@layout)
      @layout = Houston::Extensions::Layout.new
    end

    def navigation
      return @navigation if defined?(@navigation)
      @navigation = Houston::Extensions::Navigation.new
    end

    def oauth
      return @oauth if defined?(@oauth)
      @oauth = Houston::Extensions::Oauth.new
    end

    def project_features
      return @project_features if defined?(@project_features)
      @project_features = Houston::Extensions::Features.new
    end

    def serializers
      return @serializers if defined?(@serializers)
      @serializers = Houston::Extensions::Serializers.new
    end

    def view
      return @view if defined?(@view)
      @view = Houston::Extensions::Views.new
    end


    def register_events(&block)
      events.register(&block)
    end

    def add_serializer(serializer)
      serializers.add(serializer)
    end

  end



  extend Extensions

  view["projects"].has :Table
  view["users"].has :Table
  view["edit_project"].has :Form
  view["edit_user"].has :Form

  project_features
    .add(:settings) { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
    .ability { |project| can?(:update, project) }

  register_events {{
    "daemon:{type}:start"   => desc("Daemon {type} is starting"),
    "daemon:{type}:started" => desc("Daemon {type} has started"),
    "daemon:{type}:restart" => desc("Daemon {type} has restarted"),
    "daemon:{type}:stop"    => desc("Daemon {type} has stopped"),

    "hooks:{type}"          => params("params").desc("/hooks/{type} was invoked"),
    "hooks:project:{type}"  => params("project", "params").desc("/hooks/project/:slug/{type} was invoked"),

    "authorization:grant"   => params("authorization").desc("Authorization was granted"),
    "authorization:revoke"  => params("authorization").desc("Authorization was revoked")
  }}

  serializers << Houston::ActiveRecordSerializer.new
  serializers << Houston::ReadonlyHashSerializer.new

end
