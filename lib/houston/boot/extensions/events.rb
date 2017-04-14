require "concurrent/array"

module Houston
  module Extensions
    class Events
      include Enumerable

      def initialize
        @events = Concurrent::Array.new
      end

      def each(&block)
        @events.each(&block)
      end

      def [](event_name)
        @events.find { |event| event.matches? event_name }
      end

      def registered?(event_name)
        @events.any? { |event| event.matches? event_name }
      end

      def register(&block)
        dsl = RegisterEventsDsl.new
        hash = dsl.instance_eval(&block)
        hash.each do |name, description|
          @events.push Event.new(name, description.to_h)
        end
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


    Event = Struct.new(:name, :description, :params) do
      def initialize(name, options)
        super name,
          options.fetch(:description),
          options.fetch(:params, [])
        @matcher = Regexp.new("\\A#{name.gsub /\{([^:}]+)\}/, "(?<\\1>[^:]+)"}\\z")
      end

      def matches?(event_name)
        @matcher === event_name # TODO: replace `===` with `.match?` on Ruby 2.4
      end
    end
  end
end
