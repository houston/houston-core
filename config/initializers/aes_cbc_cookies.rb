# Workaround for OpenSSL 3 / Ruby 2.6 incompatibility with Rails 6's AES-256-GCM
# encrypted cookies. Hitting any cookie-encrypting code path (e.g. Devise's
# warden session storage) throws OpenSSL::Cipher::CipherError "couldn't set
# additional authenticated data" because Ruby's bundled OpenSSL bindings refuse
# to set AAD on a freshly-initialized cipher. Reverting to AES-256-CBC (the
# pre-Rails-5.2 default) sidesteps AEAD entirely.
#
# Safe for local development. For production, upgrade Ruby (2.7+ ships with
# OpenSSL 1.1 bindings that work, or 3.1+ has fixed AEAD) rather than carrying
# this override.

Rails.application.config.action_dispatch.use_authenticated_message_encryption = false
Rails.application.config.action_dispatch.encrypted_cookie_cipher = "aes-256-cbc"
Rails.application.config.active_support.use_authenticated_message_encryption = false
