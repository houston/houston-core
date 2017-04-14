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
          extend Houston::Extensions.const_get(:"Has#{constant}")
        end
        self
      end

      def reset!; end
    end
  end
end
