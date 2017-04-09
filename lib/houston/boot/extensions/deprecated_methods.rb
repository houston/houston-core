module Houston
  module Extensions
    module DeprecatedMethods


      def add_project_column(slug, &block)
        Houston.deprecation_notice 'Houston.add_project_column is deprecated and will be removed in houston-core 1.0; use Houston.views["project"].add_column instead'

        dsl = DeprecatedColumnDsl.new
        dsl.instance_eval(&block)
        dsl.add_column_to "projects"
      end

      def add_user_option(slug, &block)
        Houston.deprecation_notice 'Houston.add_user_option is deprecated and will be removed in houston-core 1.0; use Houston.views["edit_user"].add_field instead'

        dsl = DeprecatedFieldDsl.new
        dsl.instance_eval(&block)
        dsl.add_field_to "edit_user"
      end

      def add_project_option(slug, &block)
        Houston.deprecation_notice 'Houston.add_project_option is deprecated and will be removed in houston-core 1.0; use Houston.views["edit_project"].add_field instead'

        dsl = DeprecatedFieldDsl.new
        dsl.instance_eval(&block)
        dsl.add_field_to "edit_project"
      end

      def add_navigation_renderer(slug, &block)
        Houston.deprecation_notice 'Houston.add_navigation_renderer is deprecated and will be removed in houston-core 1.0; use Houston.navigation.add_link instead'

        dsl = DeprecatedNavigationDsl.new
        dsl.instance_eval(&block)
        dsl.add_to_navigation(slug)
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

        def add_column_to(view_name)
          column = Houston.view[view_name].add_column @name, &@render_block
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

        def add_field_to(view_name)
          Houston.view[view_name].add_field @label, &@render_block
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
            link.content { @name } unless @name == slug.to_s.titleize
          end
        end
      end

    end
  end
end
