module Houston
  class Oauth
    attr_reader :providers # <-- should be readonly

    def initialize
      @providers = [] # <-- does it need to be threadsafe?
    end

    def add_provider(name, &block)
      provider = Houston::Provider.new
      provider.name = name.to_sym
      ProviderDsl.new(provider).instance_eval(&block)

      raise ArgumentError, "Provider must define a site" if provider.site.blank?
      raise ArgumentError, "Provider must define a authorize_path" if provider.authorize_path.blank?
      raise ArgumentError, "Provider must define a token_path" if provider.token_path.blank?

      @providers.push provider
      provider
    end

    def get_provider(name)
      name = name.to_sym
      providers.detect { |provider| provider.name == name }
    end

  private

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
