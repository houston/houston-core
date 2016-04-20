module Oauth
  class Provider < ActiveRecord::Base
    self.table_name = "oauth_providers"

    validates :name, :site, :authorize_path, :token_path, :client_id, :client_secret, presence: true

    def authorize_url(params={})
      client.auth_code.authorize_url params.merge(redirect_uri: oauth2_callback_url)
    end

    def redeem_access_token(code, params={})
      client.auth_code.get_token(code, params.merge(redirect_uri: oauth2_callback_url))
    end

    def refresh_access_token(authorization)
      OAuth2::AccessToken.from_hash(client, authorization.attributes).refresh!
    end

  private

    def client
      @client ||= OAuth2::Client.new(
        client_id,
        client_secret,
        site: site,
        authorize_url: authorize_path,
        token_url: token_path)
    end

    def oauth2_callback_url
      "http://#{Houston.host}/oauth2/callback"
    end

  end
end
