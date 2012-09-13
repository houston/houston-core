def Rails.root_url
  Rails.application.routes.url_helpers.root_url(Rails.configuration.action_mailer.default_url_options)
end
