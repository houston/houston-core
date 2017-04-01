require "concurrent/hash"

module Houston
  class Views
    def initialize
      @views = Concurrent::Hash.new do |hash, key|
        hash[key] = Houston::View.new
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

    def reset!
    end
  end


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

  module AbilityBlock
    def ability(&block)
      __getobj__.instance_variable_set :@ability_block, block
    end
  end


  module View::Table
    attr_reader :columns

    def self.extended(view)
      view.instance_variable_set :@columns, []
    end

    def add_column(name, &block)
      ColumnBuilder.new(Column.new(name).tap do |column|
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

    class ColumnBuilder < SimpleDelegator
      include AbilityBlock
    end
  end


  module View::Form
    attr_reader :fields

    def self.extended(view)
      view.instance_variable_set :@fields, []
    end

    def add_field(label, &block)
      FieldBuilder.new(Field.new(label).tap do |field|
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
        "__props_#{label.gsub(" ", "_").underscore}"
      end
    end

    class FieldBuilder < SimpleDelegator
      include AbilityBlock
    end
  end


end
