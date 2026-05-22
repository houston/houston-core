namespace :beltic do
  desc "Issue Houston's own business credential (one-time KYB bootstrap). Prints the credential_id to set as BELTIC_ORG_CREDENTIAL_ID."
  task bootstrap_business_credential: :environment do
    unless Houston::Beltic.config.configured?
      abort "BELTIC_API_KEY is not set. Configure it before bootstrapping."
    end

    if Houston::Beltic.config.org_credential_id && !Houston::Beltic.config.org_credential_id.empty?
      puts "[Beltic] BELTIC_ORG_CREDENTIAL_ID is already set: #{Houston::Beltic.config.org_credential_id}"
      puts "[Beltic] Refusing to issue a new business credential. Revoke the existing one first if you really want to re-issue."
      exit 0
    end

    org_name             = ENV.fetch("HOUSTON_ORG_NAME") { abort("Set HOUSTON_ORG_NAME") }
    registration_number  = ENV.fetch("HOUSTON_ORG_REGISTRATION") { abort("Set HOUSTON_ORG_REGISTRATION (e.g. EIN 84-3217605)") }
    jurisdiction         = ENV.fetch("HOUSTON_ORG_JURISDICTION", "US")
    business_type        = ENV.fetch("HOUSTON_ORG_BUSINESS_TYPE", "company")

    subject = {
      type:                "organisation",
      id:                  "org_houston_#{SecureRandom.hex(4)}",
      registration_number: registration_number,
      jurisdiction:        jurisdiction,
    }

    claims = {
      kyb_status:        "pending",
      business_type:     business_type,
      jurisdiction:      jurisdiction,
      registered_name:   org_name,
      tax_id_verified:   false,
    }

    puts "[Beltic] Submitting business credential for #{org_name}…"
    response = Houston::Beltic.issuer.issue_business(subject: subject, claims: claims)

    credential_id = response["credential_id"] || response["id"]
    org_subject_id = response.dig("subject", "id") || subject[:id]
    puts ""
    puts "[Beltic] Business credential issued."
    puts "         credential_id:    #{credential_id}"
    puts "         subject.id:       #{org_subject_id}"
    puts "         status:           #{response["status"]}"
    puts "         expires_at:       #{response["expires_at"]}"
    puts ""
    puts "Set BOTH in your environment so future user/agent credentials reference them correctly:"
    puts ""
    puts "  BELTIC_ORG_CREDENTIAL_ID=#{credential_id}     # for our own records"
    puts "  BELTIC_ORG_SUBJECT_ID=#{org_subject_id}       # passed as parent_business_id on user/agent credentials"
    puts ""

    if defined?(VerifiableCredential)
      VerifiableCredential.create!(
        credential_id:   credential_id,
        credential_type: "business",
        subject_type:    "Organization",
        subject_id:      0,
        status:          response["status"] || "active",
        signed_payload:  response["signed_payload"],
        claims:          response["claims"] || claims,
        issued_at:       response["issued_at"],
        expires_at:      response["expires_at"],
        raw_response:    response,
      )
      puts "[Beltic] Persisted to verifiable_credentials table."
    end
  end

  desc "Register Houston's webhook endpoint with Beltic (POST /v1/audit/streams). Requires BELTIC_WEBHOOK_URL to be set to a publicly-reachable URL."
  task subscribe_webhooks: :environment do
    unless Houston::Beltic.config.configured?
      abort "BELTIC_API_KEY is not set."
    end

    url = ENV.fetch("BELTIC_WEBHOOK_URL") do
      abort("Set BELTIC_WEBHOOK_URL (publicly-reachable, e.g. https://houston.example.com/webhooks/beltic)")
    end

    secret = ENV["BELTIC_WEBHOOK_SECRET"]
    if secret.nil? || secret.length < 32
      secret = SecureRandom.hex(32)
      puts "[Beltic] No BELTIC_WEBHOOK_SECRET set — generated one for you: #{secret}"
      puts "         Set this as ENV BELTIC_WEBHOOK_SECRET so the controller can verify incoming events."
    end

    body = {
      url:    url,
      secret: secret,
      event_filter: ENV.fetch("BELTIC_WEBHOOK_EVENTS", "credential.issued,credential.revoked,credential.suspended,credential.reactivated").split(","),
    }

    response = Houston::Beltic.client.post("/audit/streams", body)
    puts "[Beltic] Webhook subscription created."
    puts "         id:           #{response["id"]}"
    puts "         url:          #{response["url"]}"
    puts "         events:       #{response["event_filter"].inspect}"
    puts "         active:       #{response["active"]}"
  end

  desc "Print Beltic config (api_key redacted) for debugging."
  task config: :environment do
    c = Houston::Beltic.config
    puts "configured?           #{c.configured?}"
    puts "base_url:             #{c.base_url}"
    puts "api_key:              #{c.api_key ? "sk_***#{c.api_key[-4..]}" : "(unset)"}"
    puts "org_credential_id:    #{c.org_credential_id || "(unset)"}"
    puts "org_subject_id:       #{c.org_subject_id || "(unset)"}"
    puts "webhook_secret:       #{c.webhook_secret ? "***" : "(unset)"}"
    puts "issuer_did:           #{c.issuer_did}"
    puts "jwks_url:             #{c.jwks_url}"
  end
end
