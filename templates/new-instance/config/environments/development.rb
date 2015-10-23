Rails.application.configure do
  # Settings specified here will take precedence over those in Houston.

  # Test emails
  config.action_mailer.delivery_method = :letter_opener
end
