require "houston/boot/serializer"
require "houston/boot/extensions/events"
require "houston/boot/extensions/layout"
require "houston/boot/extensions/navigation"
require "houston/boot/extensions/oauth"
require "houston/boot/extensions/features"
require "houston/boot/extensions/serializers"
require "houston/boot/extensions/view"
require "houston/boot/extensions/deprecated_methods"
require "houston/boot/serializers/active_record_serializer"
require "houston/boot/serializers/readonly_hash_serializer"


module Houston
  module Extensions
    include Houston::Extensions::DeprecatedMethods


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





    def add_project_header_command(slug, &block)
      dsl = ProjectBannerFeatureDsl.new(ProjectBannerFeature.new)
      dsl.instance_eval(&block)
      feature = dsl.feature
      feature.slug = slug

      @project_header_commands[slug] = feature
    end

    def project_header_commands
      @project_header_commands.values
    end



  private

    class ProjectBannerFeature
      attr_accessor :partial
      attr_accessor :ability_block
      attr_accessor :slug

      def permitted?(ability, project)
        return true if ability_block.nil?
        ability_block.call ability, project
      end
    end

    class ProjectBannerFeatureDsl
      attr_reader :feature

      def initialize(feature)
        @feature = feature
      end

      def partial(value)
        feature.partial = value
      end

      def ability(&block)
        feature.ability_block = block
      end
    end

  end



  @project_header_commands = {}
  extend Houston::Extensions
end



Houston.view["projects"].has :Table
Houston.view["users"].has :Table
Houston.view["edit_project"].has :Form
Houston.view["edit_user"].has :Form

Houston.project_features
  .add(:settings) { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
  .ability { |project| can?(:update, project) }

Houston.register_events {{

  "daemon:{type}:start"             => desc("Daemon {type} has started"),
  "daemon:{type}:restart"           => desc("Daemon {type} has restarted"),
  "daemon:{type}:stop"              => desc("Daemon {type} has stopped"),

  "hooks:{type}"                    => params("params").desc("/hooks/{type} was invoked"),
  "hooks:project:{type}"            => params("project", "params").desc("/hooks/project/:slug/{type} was invoked"),

  "authorization:grant"             => params("authorization").desc("Authorization was granted"),
  "authorization:revoke"            => params("authorization").desc("Authorization was revoked")

}}

Houston.serializers << Houston::ActiveRecordSerializer.new

Houston.serializers << Houston::ReadonlyHashSerializer.new
