module Houston
  class Layout
    attr_reader :extensions_by_layout

    def initialize
      @extensions_by_layout =
        { "application" => Extensions.new,
          "dashboard" => Extensions.new }
    end

    def [](layout)
      raise ArgumentError, "#{layout} is not a layout. Valid layouts are #{extensions_by_layout.keys.join(", ")}" unless extensions_by_layout.key?(layout)
      ExtensionDsl.new(extensions_by_layout, layout)
    end

    def all
      ExtensionDsl.new(extensions_by_layout, *extensions_by_layout.keys)
    end

    delegate :meta, :stylesheets, :footers, :scripts, to: :all

    class ExtensionDsl

      def initialize(registry, *layouts)
        @registry = registry
        @layouts = layouts
      end

      def meta(&block)
        add :meta, block
      end

      def stylesheets(&block)
        add :stylesheets, block
      end

      def footers(&block)
        add :footers, block
      end

      def scripts(&block)
        add :scripts, block
      end

    private
      attr_reader :registry, :layouts

      def add(method, block)
        layouts.each do |layout|
          registry[layout].public_send(method) << block
        end
      end

    end

    Extensions = Struct.new(:meta, :stylesheets, :footers, :scripts) do
      def initialize
        super [], [], [], []
      end
    end

  end
end
