require "concurrent/array"
require "delegate"
require "houston/boot/extensions/dsl"

module Houston
  module Extensions
    class Navigation
      attr_reader :links

      def initialize
        @links = Concurrent::Array.new
      end

      def add_link(content, &path_block)
        if content.is_a?(Symbol)
          slug = content
          content = slug.to_s.titleize
        else
          slug = content.underscore.to_sym
        end
        Chain(AbilityBlock, AcceptsName, Link.new(slug, content).tap do |link|
          link.instance_variable_set :@path_block, path_block
          @links.push link
        end)
      end
      alias :add :add_link
      alias :<< :add_link

      def slugs
        links.map(&:slug)
      end

      def [](slug)
        links.find { |link| link.slug == slug }
      end
    end

    Link = Struct.new(:slug, :name) do
      include Permitted, LinkTo
    end
  end
end
