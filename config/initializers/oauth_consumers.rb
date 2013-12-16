OAUTH_CREDENTIALS = {}.tap do |credentials|

  github = Houston.config.github.pick(:key, :secret)
  unless github.empty?
    credentials.merge!(github: github.merge(
      expose: false, # expose client at /oauth_consumers/twitter/client see docs
      oauth_version: 2,
      scope: "repo",
      options: {
        site: "https://github.com",
        authorize_url: "/login/oauth/authorize",
        token_url: "/login/oauth/access_token"
    }))
  end

end.freeze

load 'oauth/models/consumers/service_loader.rb'
