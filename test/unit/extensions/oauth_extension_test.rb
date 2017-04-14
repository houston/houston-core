require "test_helper"

class OauthExtensionTest < ActiveSupport::TestCase

  teardown do
    Houston.oauth.reset!
  end


  context "Houston.oauth" do
    should "be an instance of Houston::Extensions::Oauth" do
      assert_kind_of Houston::Extensions::Oauth, Houston.oauth
    end
  end


  context "#add_provider" do
    should "raise an ArgumentError unless site, authorize_path, and token_path are defined" do
      %w{site authorize_path token_path}.combination(2).each do |properties|
        assert_raises ArgumentError do
          Houston.oauth.add_provider :example do
            properties.each do |property|
              public_send property, "example"
            end
          end
        end
      end
    end

    should "configure a new Oauth Provider" do
      Houston.oauth.add_provider :office365_test do
        site "https://login.microsoftonline.com"
        authorize_path "/common/oauth2/v2.0/authorize"
        token_path "/common/oauth2/v2.0/token"
      end

      assert Houston.oauth.providers.member?(:office365_test),
        "Expected :office365_test to have been registered"
    end
  end


  context "Houston.config.oauth" do
    should "raise a ProviderNotFound unless given a regisered provider" do
      assert_raises Houston::Extensions::Oauth::ProviderNotFound do
        config.oauth :nope do
          client_id "example"
          client_secret "example"
        end
      end
    end

    context ":office365_test" do
      setup do
        Houston.oauth.add_provider :office365_test do
          site "https://login.microsoftonline.com"
          authorize_path "/common/oauth2/v2.0/authorize"
          token_path "/common/oauth2/v2.0/token"
        end
      end

      should "raise an ArgumentError unless client_id and client_secret are defined" do
        %w{client_id client_secret}.each do |property|
          assert_raises ArgumentError do
            config.oauth :office365_test do
              public_send property, "example"
            end
          end
        end
      end

      should "activate an Oauth Provider" do
        config.oauth :office365_test do
          client_id "example"
          client_secret "example"
        end

        assert config.oauth_providers.member?("office365_test"),
          "Expected \"office365_test\" to be included among the configured Oauth Providers (#{Houston.config.oauth_providers.inspect})"
      end
    end
  end


private

  def config
    @config ||= Houston::Configuration.new
  end

end
