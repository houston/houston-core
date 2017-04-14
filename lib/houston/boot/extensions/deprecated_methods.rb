module Houston
  module Extensions
    module DeprecatedMethods


      def add_project_column(_slug, &block)
        Houston.deprecation_notice 'Houston.add_project_column is deprecated and will be removed in houston-core 1.0; use Houston.views["project"].add_column instead'

        dsl = DeprecatedColumnDsl.new
        dsl.instance_eval(&block)
        dsl.add_to Houston.view["projects"]
      end

      def add_user_option(_slug, &block)
        Houston.deprecation_notice 'Houston.add_user_option is deprecated and will be removed in houston-core 1.0; use Houston.views["edit_user"].add_field instead'

        dsl = DeprecatedFieldDsl.new
        dsl.instance_eval(&block)
        dsl.add_to Houston.view["edit_user"]
      end

      def add_project_option(_slug, &block)
        Houston.deprecation_notice 'Houston.add_project_option is deprecated and will be removed in houston-core 1.0; use Houston.views["edit_project"].add_field instead'

        dsl = DeprecatedFieldDsl.new
        dsl.instance_eval(&block)
        dsl.add_to Houston.view["edit_project"]
      end

      def add_navigation_renderer(slug, &block)
        Houston.deprecation_notice 'Houston.add_navigation_renderer is deprecated and will be removed in houston-core 1.0; use Houston.navigation.add_link instead'

        dsl = DeprecatedNavigationDsl.new
        dsl.instance_eval(&block)
        dsl.add_to_navigation(slug)
      end

      def add_project_feature(slug, &block)
        Houston.deprecation_notice 'Houston.add_project_feature is deprecated and will be removed in houston-core 1.0; use Houston.project_features.add instead'

        dsl = DeprecatedProjectFeatureDsl.new
        dsl.instance_eval(&block)
        dsl.add_to_project_features(slug)
      end






      class DeprecatedColumnDsl
        def name(value)
          @name = value
        end

        def html(&block)
          @render_block = block
        end

        def ability(&block)
          @ability_block = block
        end

        def add_to(view)
          column = view.add_column @name, &@render_block
          ability_block = @ability_block
          column.ability { ability_block.call(self) } if ability_block
          column
        end
      end

      class DeprecatedFieldDsl
        attr_reader :label, :render_block

        def name(value)
          @label = value
        end

        def html(&block)
          @render_block = block
        end

        def add_to(view)
          render_block = @render_block
          view.add_field(@label) { |*args| instance_exec(*args, &render_block).html_safe }
        end
      end

      class DeprecatedNavigationDsl
        def name(value)
          @name = value
        end

        def path(&block)
          @path_block = block
        end

        def ability(&block)
          @ability_block = block
        end

        def add_to_navigation(slug)
          Houston.navigation.add_link(slug, &@path_block).tap do |link|
            ability_block = @ability_block
            link.ability { ability_block.call(self) } if ability_block
            link.name { @name } unless @name == slug.to_s.titleize
          end
        end
      end

      class DeprecatedProjectFeatureDsl
        def initialize
          @field_blocks = []
        end

        def name(value)
          @name = value
        end

        def path(&block)
          @path_block = block
        end

        def ability(&block)
          @ability_block = block
        end

        def field(_slug, &block)
          @field_blocks.push block
        end

        def add_to_project_features(slug)
          raise ArgumentError, "Project Feature must supply name, but #{slug.inspect} doesn't" unless @name
          raise ArgumentError, "Project Feature must supply path lambda, but #{slug.inspect} doesn't" unless @path_block

          Houston.project_features.add(slug, &@path_block).tap do |feature|
            ability_block = @ability_block
            feature.ability { |project| ability_block.call(self, project) } if ability_block
            feature.name { @name } unless @name == slug.to_s.titleize

            @field_blocks.each do |block|
              dsl = DeprecatedFieldDsl.new
              dsl.instance_eval(&block)
              dsl.add_to feature
            end
          end
        end
      end

    end
  end
end
