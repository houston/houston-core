# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
unless Rails.env.production?
  Houston::Application.config.secret_key_base = "8cf48c792d860953a74ecaa7c779c6019ecddf39a03300a9aed505662f519cf933b4b0ecba3bea4f0eaaf3debd09b08c3e2bd87b9d30be8df0b1166ab4962752"
else
  Houston::Application.config.secret_key_base = ENV["HOUSTON_SECRET_KEY_BASE"]
end
