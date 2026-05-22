return unless defined?(Lockbox)

# Master key for at-rest encryption of secrets (e.g. VerifiableCredential#signed_payload).
# Generate with:  bundle exec rake "lockbox:generate_key"
# Set as ENV LOCKBOX_MASTER_KEY or in Rails encrypted credentials (preferred for prod).
Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"] || Rails.application.credentials.dig(:lockbox, :master_key)

if Rails.env.production? && Lockbox.master_key.to_s.empty?
  Rails.logger.warn("[Lockbox] LOCKBOX_MASTER_KEY is not set — encrypted attributes will fail")
end
