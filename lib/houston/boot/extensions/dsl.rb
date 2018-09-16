require "delegate"

module Houston
  module Extensions
    module Permitted
      def permitted?(ability, *args)
        return true if @ability_block.nil?
        ability.instance_exec(*args, &@ability_block)
      end
    end

    module Render
      def render(view, *args)
        view.instance_exec(*args, &@render_block)
      end
    end

    module LinkTo
      def path(*args)
        @path_block.call(*args)
      end
    end

    module AbilityBlock
      def ability(&block)
        __getobj__.instance_variable_set :@ability_block, block
        self
      end
    end

    module AcceptsName
      def name(name)
        __getobj__.name = name
        self
      end
    end

    module HasTable
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

    module HasForm
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

def Chain(*modules)
  object = modules.pop
  Class.new(SimpleDelegator).new(object).tap do |builder|
    modules.each do |mod|
      builder.extend mod
    end
  end
end
