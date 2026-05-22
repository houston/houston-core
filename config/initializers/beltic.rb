require "houston/beltic"

Houston::Beltic.configure do |b|
  b.api_key           = ENV["BELTIC_API_KEY"]
  b.base_url          = ENV["BELTIC_BASE_URL"] || "https://api.beltic.com/v1"
  b.webhook_secret    = ENV["BELTIC_WEBHOOK_SECRET"]
  b.org_credential_id = ENV["BELTIC_ORG_CREDENTIAL_ID"]
  b.org_subject_id    = ENV["BELTIC_ORG_SUBJECT_ID"]
end

if Rails.env.production? && !Houston::Beltic.config.configured?
  Rails.logger.warn("[Beltic] BELTIC_API_KEY is not set — VC issuance will be disabled")
end
