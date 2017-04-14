require "houston/boot/serializer"
require "houston/boot/extensions/events"
require "houston/boot/extensions/layout"
require "houston/boot/extensions/navigation"
require "houston/boot/extensions/oauth"
require "houston/boot/extensions/serializers"
require "houston/boot/extensions/view"
require "houston/boot/extensions/deprecated_methods"


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





    def available_project_features
      @available_project_features.keys
    end

    def get_project_feature(slug)
      @available_project_features.fetch(slug)
    end

    def add_project_feature(slug, &block)
      dsl = FeatureDsl.new(ProjectFeature.new)
      dsl.instance_eval(&block)
      feature = dsl.feature
      feature.slug = slug
      raise ArgumentError, "Project Feature must supply name, but #{slug.inspect} doesn't" unless feature.name
      raise ArgumentError, "Project Feature must supply path lambda, but #{slug.inspect} doesn't" unless feature.path_block

      @available_project_features[slug] = feature
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

    class GlobalFeature
      attr_accessor :name, :slug, :icon, :path_block, :ability_block

      def path
        path_block.call
      end

      def permitted?(ability)
        return true if ability_block.nil?
        ability_block.call ability
      end
    end

    class ProjectFeature < GlobalFeature
      attr_accessor :fields

      def initialize
        self.fields = []
      end

      def project_path(project)
        path_block.call project
      end
      alias :path :project_path

      def permitted?(ability, project)
        return true if ability_block.nil?
        ability_block.call ability, project
      end
    end

    class FeatureDsl
      attr_reader :feature

      def initialize(feature)
        @feature = feature
      end

      def name(value)
        feature.name = value
      end

      def path(&block)
        feature.path_block = block
      end

      def ability(&block)
        feature.ability_block = block
      end

      def field(slug, &block)
        dsl = FormBuilderDsl.new
        dsl.instance_eval(&block)
        form = dsl.form
        form.slug = slug
        feature.fields.push form
      end
    end

    class ProjectFeatureForm
      attr_accessor :slug, :name, :render_block

      def render(view, f)
        view.instance_exec(f, &render_block).html_safe
      end
    end

    class FormBuilderDsl
      attr_reader :form

      def initialize
        @form = ProjectFeatureForm.new
      end

      def name(value)
        form.name = value
      end

      def html(&block)
        form.render_block = block
      end
    end

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



  @available_project_features = {}
  @project_header_commands = {}
  extend Houston::Extensions
end

Houston.view["projects"].has :Table
Houston.view["users"].has :Table
Houston.view["edit_project"].has :Form
Houston.view["edit_user"].has :Form
