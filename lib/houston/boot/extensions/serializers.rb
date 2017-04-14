require "concurrent/array"

module Houston
  module Extensions
    class Serializers
      include Enumerable

      def initialize
        @serializers = Concurrent::Array.new
      end

      def each(&block)
        @serializers.each(&block)
      end

      def add(serializer)
        serializer = serializer.new if serializer.is_a?(Class)

        [:applies_to?, :pack].each do |method|
          next if serializer.respond_to?(method)
          raise ArgumentError, "`serializer` must respond to `#{method}`"
        end

        @serializers.push serializer
      end
      alias :<< :add
    end
  end
end
