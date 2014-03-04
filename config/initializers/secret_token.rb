# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
if Rails.env.production?
  Houston::Application.config.secret_key_base = ENV["SECRET_KEY_BASE"]
else
  Houston::Application.config.secret_key_base = '3dc8f02c16cfe71fb33e6687638011a5bd436c8eae2824f4aca0eb3ddd68b4f7bcac1d05b79d2350f1012495429a7adb11cbb4f37004c393696d85108a3e700a'
end
