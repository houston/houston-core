require "concurrent/hash"
require "houston/boot/extensions/dsl"

module Houston
  module Extensions
    class Views
      def initialize
        @views = Concurrent::Hash.new do |hash, key|
          hash[key] = Houston::Extensions::View.new
        end
      end

      def [](view)
        @views[view]
      end

      def reset!
        @views.values.each(&:reset!)
      end
    end


    class View
      def has(*constants)
        constants.each do |constant|
          extend self.class.const_get(constant)
        end
        self
      end

      def reset!; end
    end


    module View::Table
      attr_reader :columns

      def self.extended(view)
        view.instance_variable_set :@columns, []
      end

      def add_column(name, &block)
        Chain(AbilityBlock, Column.new(name).tap do |column|
          column.instance_variable_set :@render_block, block
          @columns << column
        end)
      end

      def reset!
        @columns = []
        super
      end

      Column = Struct.new(:name) do
        include Permitted, Render
      end
    end


    module View::Form
      attr_reader :fields

      def self.extended(view)
        view.instance_variable_set :@fields, []
      end

      def add_field(label, &block)
        Chain(AbilityBlock, Field.new(label).tap do |field|
          field.instance_variable_set :@render_block, block
          @fields << field
        end)
      end

      def reset!
        @fields = []
        super
      end

      Field = Struct.new(:label) do
        include Permitted, Render

        def id
          "__props_#{label.tr(" ", "_").underscore}"
        end
      end
    end
  end
end
