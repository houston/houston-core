require "houston/boot/serializer"


module Houston
  module Extensions
    attr_reader :events, :serializers



    def available_navigation_renderers
      @navigation_renderers.keys
    end

    def get_navigation_renderer(name)
      @navigation_renderers.fetch(name)
    end

    def add_navigation_renderer(slug, &block)
      dsl = FeatureDsl.new(GlobalFeature.new)
      dsl.instance_eval(&block)
      feature = dsl.feature
      feature.slug = slug
      raise ArgumentError, "Renderer must supply name, but #{slug.inspect} doesn't" unless feature.name
      raise ArgumentError, "Renderer must supply path lambda, but #{slug.inspect} doesn't" unless feature.path_block

      @navigation_renderers[slug] = feature
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



    def add_user_option(slug, &block)
      dsl = FormBuilderDsl.new
      dsl.instance_eval(&block)
      form = dsl.form
      form.slug = slug

      @user_options[slug] = form
    end

    def user_options
      @user_options.values
    end



    def add_project_option(slug, &block)
      dsl = FormBuilderDsl.new
      dsl.instance_eval(&block)
      form = dsl.form
      form.slug = slug

      @project_options[slug] = form
    end

    def project_options
      @project_options.values
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



    def add_project_column(slug, &block)
      dsl = ProjectColumnDsl.new(ProjectColumn.new)
      dsl.instance_eval(&block)
      feature = dsl.feature
      feature.slug = slug

      @project_columns[slug] = feature
    end

    def project_columns
      @project_columns.values
    end



    def registered_event?(event_name)
      events.any? { |event| event.matches? event_name }
    end

    def get_registered_event(event_name)
      events.find { |event| event.matches? event_name }
    end

    def register_event(name, description)
      events.push Event.new(name, description)
    end

    def register_events(&block)
      dsl = RegisterEventsDsl.new
      hash = dsl.instance_eval(&block)
      hash.each do |name, description|
        register_event(name, description.to_h)
      end
    end



    def add_serializer(serializer)
      [:applies_to?, :pack].each do |method|
        next if serializer.respond_to?(method)
        raise ArgumentError, "`serializer` must respond to `#{method}`"
      end

      @serializers.push serializer
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

    class ProjectColumn
      attr_accessor :html_block
      attr_accessor :ability_block
      attr_accessor :slug
      attr_accessor :name

      def render(project)
        html_block.call project
      end

      def permitted?(ability)
        return true if ability_block.nil?
        ability_block.call ability
      end
    end

    class ProjectColumnDsl
      attr_reader :feature

      def initialize(feature)
        @feature = feature
      end

      def name(value)
        feature.name = value
      end

      def html(&block)
        feature.html_block = block
      end

      def ability(&block)
        feature.ability_block = block
      end
    end

    class RegisterEventsDsl
      def params(*params)
        RegisterEventDsl.new.params(*params)
      end

      def description(value)
        RegisterEventDsl.new.description(value)
      end
      alias :desc :description
    end

    class RegisterEventDsl
      def initialize
        @hash = {}
      end

      def params(*params)
        @hash[:params] = params
        self
      end

      def description(value)
        @hash[:description] = value
        self
      end
      alias :desc :description

      def to_h
        @hash
      end
    end

    class Event
      attr_reader :name, :description, :params

      def initialize(name, options)
        @name = name
        @description = options.fetch(:description)
        @params = options.fetch(:params, [])
        @matcher = Regexp.new("\\A#{name.gsub /\{([^:}]+)\}/, "(?<\\1>[^:]+)"}\\z")
      end

      def matches?(event_name)
        @matcher === event_name
      end
    end

  end



  @navigation_renderers = {}
  @available_project_features = {}
  @user_options = {}
  @project_options = {}
  @project_columns = {}
  @project_header_commands = {}
  @events = []
  @event_matchers = []
  @serializers = []
  extend Houston::Extensions
end
