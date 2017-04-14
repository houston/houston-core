require "concurrent/array"

module Houston
  module Extensions
    class Oauth
      class ProviderNotFound < ArgumentError; end

      def initialize
        reset!
      end

      def reset!
        @providers = Concurrent::Hash.new
      end

      def providers
        @providers.keys
      end

      def add_provider(name, &block)
        provider = Houston::Provider.new(name.to_sym)
        ProviderDsl.new(provider).instance_eval(&block)

        raise ArgumentError, "Provider must define a site" if provider.site.blank?
        raise ArgumentError, "Provider must define a authorize_path" if provider.authorize_path.blank?
        raise ArgumentError, "Provider must define a token_path" if provider.token_path.blank?

        @providers[provider.name] = provider
      end

      def get_provider(name)
        name = name.to_sym
        @providers.fetch(name)
      rescue KeyError
        puts "registered providers: #{providers.inspect}"
        raise ProviderNotFound, "An Oauth Provider named #{name.inspect} has not been registered"
      end


      class ProviderDsl
        attr_reader :provider

        def initialize(provider)
          @provider = provider
        end

        def site(value)
          provider.site = value
        end

        def authorize_path(value)
          provider.authorize_path = value
        end

        def token_path(value)
          provider.token_path = value
        end
      end

    end
  end
end
