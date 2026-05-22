# Local Development — Houston ↔ Beltic

End-to-end setup for running Houston + Beltic locally and walking the integration
flow against a real Beltic API instance (not a mock).

## Prereqs

- Ruby 2.6.10 (Houston's pinned version — check `ruby --version`)
- Bundler (`gem install bundler`)
- PostgreSQL 9.4+ (`brew install postgresql@14 && brew services start postgresql@14`)
- pnpm + Node 22 (for Beltic platform)
- Docker + Docker Compose (for Beltic's MongoDB / LocalStack / nginx)
- `ngrok` (only if you want Beltic to deliver webhooks to your local Houston)
- `gh` CLI (already installed)

## 1. Start Beltic locally

In one terminal, in the Beltic platform repo:

```bash
cd ~/Documents/Work/Beltic/platform

# First time only:
pnpm install
pnpm build
make env-local-sync          # pulls local env from 1Password — auth first

# Every session:
make dev-up                  # starts MongoDB + LocalStack + nginx
pnpm aws:terraform:local     # bootstraps local AWS resources (KMS, DynamoDB, S3)
pnpm dev                     # esbuild watchers + lambda log streamer
```

When ready, the Credentials API will be reachable at **http://localhost:8080/v1**.

Sanity check it's alive:

```bash
curl -s http://localhost:8080/.well-known/jwks.json | jq .keys[0].kid
```

## 2. Create a Beltic API key for Houston

The Beltic Console UI (`http://localhost:3000` once running) lets you create API
keys against a WorkOS organization. For local dev:

1. Sign into the Console with your WorkOS test account.
2. Switch to a sandbox organization (or create one).
3. Settings → API keys → Create key.
4. Grant scopes: `credentials:write`, `credentials:read`, `credentials:revoke`, `credentials:verify`.
5. Copy the `sk_staging_…` value — Beltic won't show it again.

(If the Console isn't running, see Beltic's own README for the seed-script path
to insert an API key directly into the local DynamoDB table.)

## 3. Set up Houston

In another terminal, in the Houston repo:

```bash
cd ~/Documents/Work/Houston/houston-core

# First time only:
gem install bundler --conservative
bundle install
bin/setup                    # creates DB, runs db:prepare

# Generate a Lockbox master key for encrypting signed_payload at rest
bundle exec rake lockbox:generate_key  # prints the key

# Create the .env from the template
cp .env.example .env         # then edit .env (see below)
```

Edit `.env` with at least:

```bash
BELTIC_API_KEY=sk_staging_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
BELTIC_BASE_URL=http://localhost:8080/v1
LOCKBOX_MASTER_KEY=<the key from lockbox:generate_key>

# Webhook subscription comes later (step 6)
```

Run the new migrations:

```bash
bin/rails db:migrate
```

## 4. Bootstrap Houston's business credential

```bash
HOUSTON_ORG_NAME="Houston Software Inc." \
HOUSTON_ORG_REGISTRATION="EIN 84-3217605" \
HOUSTON_ORG_JURISDICTION="US" \
HOUSTON_ORG_BUSINESS_TYPE="company" \
bundle exec bin/rails beltic:bootstrap_business_credential
```

The task prints:

```
BELTIC_ORG_CREDENTIAL_ID=cred_abc123…
BELTIC_ORG_SUBJECT_ID=org_houston_a8f3…
```

Copy both into `.env`. Houston needs the subject_id as `parent_business_id` on
every downstream user/agent credential, and the credential_id for its own
records.

Verify config:

```bash
bundle exec bin/rails beltic:config
```

## 5. Start Houston

```bash
bundle exec bin/rails server
```

Browse to **http://localhost:3000**. Sign up (or use Devise's invitation flow if
you've seeded an admin), then visit:

- `/identity/verify/new` — self-attestation flow
- `/settings/identity` — your verified credential card
- `/agents/new` — authorize an agent (requires verified identity)
- `/settings/agents` — list of authorized agents

Each form submission enqueues `Beltic::IssueCredentialJob`. The job calls Beltic
at `http://localhost:8080/v1/credentials` and persists the returned credential
into the `verifiable_credentials` table.

Watch the logs side-by-side: Houston's `log/development.log` shows the outbound
Faraday calls; the `pnpm dev` window shows Beltic's lambda processing them.

## 6. (Optional) Subscribe to Beltic webhooks

Beltic delivers `credential.revoked` / `credential.issued` / `credential.suspended`
events to a URL you register. For local dev, expose Houston with ngrok:

```bash
ngrok http 3000
# copy the https URL it prints, e.g. https://abc123.ngrok.io
```

Then:

```bash
BELTIC_WEBHOOK_URL=https://abc123.ngrok.io/webhooks/beltic \
BELTIC_WEBHOOK_SECRET=$(openssl rand -hex 32) \
bundle exec bin/rails beltic:subscribe_webhooks
```

Copy the printed `BELTIC_WEBHOOK_SECRET` into `.env` and restart the Rails server
so `Webhooks::BelticController` can verify incoming signatures.

To trigger a webhook, revoke a credential from the Beltic side:

```bash
curl -X POST http://localhost:8080/v1/credentials/cred_xxx/revoke \
  -H "X-Api-Key: sk_staging_…" \
  -H "Content-Type: application/json" \
  -d '{"reason":"testing"}'
```

You should see the row in `verifiable_credentials` flip to `status=revoked`
within a second or two.

## 7. End-to-end smoke test

Walk this happy path to confirm everything is wired:

1. Sign up as `alice@example.com` in Houston.
2. Visit `/identity/verify/new`. Submit:
   - Nationality: US
   - DOB: 1990-01-01
   - ID document type: passport
   - ID document country: US
   - Check all three declarations.
3. Job runs. Within 1–2s, `/settings/identity` shows the verified credential card with `trust_level: idv_verified`.
4. Visit `/agents/new`. Create "Personal assistant" with daily limit $250, per-tx $100, currencies USD+BRL.
5. Job runs. `/settings/agents` lists the agent with its credential ID.
6. Revoke from Beltic (curl above). Webhook fires (if subscribed). `/settings/agents` shows revoked.
7. Manually re-verify the agent's credential via the local Verifier:
   ```ruby
   # bundle exec bin/rails runner
   vc = VerifiableCredential.last
   Houston::Beltic.verifier.verify(vc.signed_payload, resource_type: "wallet",
                                                       action: "checkout",
                                                       transaction_amount: 5000,
                                                       transaction_currency: "USD")
   # => Result with valid?: true, reason: :ok (or :revoked if step 6 happened)
   ```

## Troubleshooting

- **`unauthorized` / `forbidden` on issue** — API key missing scopes; recreate with `credentials:write`.
- **`self_attestation_incomplete`** — the controller didn't set the flag because not all 3 declarations were checked.
- **`delegated_by_required` on agent issue** — the user's credential ID isn't being resolved. Verify `current_user.beltic_user_credential&.active?` returns true.
- **Webhook 401** — `BELTIC_WEBHOOK_SECRET` mismatch between what you sent to `subscribe_webhooks` and what's in `.env`. They must match exactly.
- **JWKS fetch fails** — check `BELTIC_BASE_URL` matches the host serving `.well-known/`. If Beltic is on localhost, the jwks_url default (`api.beltic.com/.well-known/jwks.json`) is wrong — override `Houston::Beltic.config.jwks_url` in `config/initializers/beltic.rb` for local dev.
- **`bin/rails db:migrate` complains about `lockbox`** — run `bundle install` to pick up the new gem.
