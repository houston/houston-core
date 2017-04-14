require "concurrent/array"
require "delegate"
require "houston/boot/extensions/dsl"

module Houston
  module Extensions
    class Features

      def initialize
        @features = Concurrent::Hash.new
      end

      def add(content, &path_block)
        if content.is_a?(Symbol)
          slug = content
          content = slug.to_s.titleize
        else
          slug = content.underscore.to_sym
        end
        Chain(AbilityBlock, AcceptsName, Feature.new(slug, content).tap do |feature|
          feature.instance_variable_set :@path_block, path_block
          feature.extend Houston::Extensions::HasForm
          @features[slug] = feature
        end)
      end
      alias :<< :add

      def all
        @features.keys
      end
      alias :to_a :all

      def [](slug)
        @features.fetch(slug)
      end
    end

    Feature = Struct.new(:slug, :name) do
      include Permitted, LinkTo
    end
  end
end
