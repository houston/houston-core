# Beltic Verifiable Credentials Integration

Status: design — implementation in progress on `beltic-integration` branch
Owner: Beltic team (alivia@beltic.com)
Design surfaces: https://www.figma.com/design/m9EpQoMdechc1XfFnCqA9I

## Why

Houston needs a portable, cryptographically-verifiable identity for two reasons:

1. **End users**: prove who Houston's users are when their agents act on their behalf — especially when those agents make purchases, sign contracts, or otherwise spend money.
2. **Houston itself (as an issuer)**: hold a Beltic-issued business credential so Houston can mint user and agent credentials under its own KYB-verified org identity.

Beltic issues W3C JWT-VCs against a documented credentials API. Houston is the integrator: it owns the UI, owns the user data, and calls Beltic's API for issuance/verification.

## Credential types we issue

Three of Beltic's four credential types apply:

| Type | Subject | When | Lifetime |
|---|---|---|---|
| `business` | Houston, Inc. (org) | One-time KYB at bootstrap | 1 yr, auto-renewed |
| `user` | A Houston user | At signup OR first agent setup | 1 yr |
| `agent_authorization` | An Agent the user has authorized | When user creates/authorizes an agent for purchases | bound to spend limits + idle timeout |

We do **not** issue `outcome_attestation` directly in v1 — that's used by Beltic Workflows for KYB outcomes. We may use it later for credential-strengthening (see below).

## End-to-end flow

```
                 ┌──────────────────────────────────────────────┐
                 │  One-time: Houston bootstrap                  │
                 │  rake beltic:bootstrap_business_credential    │
                 │  → POST /v1/credentials (credential_type:     │
                 │       business)                               │
                 │  → stored in Houston.config.beltic.org_cred   │
                 └──────────────────────────────────────────────┘

User signup / first-agent setup:
   User opens self-attestation modal in Houston (Figma: "Verify Your Identity")
   → Houston collects: nationality, DOB, ID doc (optional), declarations
   → POST /v1/credentials  (type: user, self_attestation_complete: true)
   → store credential_id + signed_payload in verifiable_credentials table
   → user.props['beltic.user_credential_id'] = ...

User authorizes an agent:
   User opens agent-authorization modal in Houston (Figma: "Authorize this agent")
   → Houston collects: daily limit, per-tx max, currencies, idle duration,
                       confirmation threshold
   → POST /v1/credentials  (type: agent_authorization,
                            delegated_by_subject_id: user_credential_id,
                            permissions: [{ resource_type:'wallet',
                                            actions:['checkout',
                                                     'payment_authorize'], ... }])
   → agent.props['beltic.agent_credential_id'] = ...

Agent makes a purchase at runtime:
   1. Agent constructs the purchase request and attaches its
      signed_payload (the JWT-VC)
   2. Houston's purchase handler calls Beltic::Verifier#verify(jwt, ctx)
      - local verification via Beltic verifier SDK (sub-ms)
      - validates: signature, not revoked, policy passes
        (transaction_amount <= permissions.conditions['lte'], currency in
         authorized_currencies, etc.)
   3. If above the user's confirmation_threshold OR policy denies: emit a
      Mission card to "Needs you" column for human approval
   4. If verified + autonomous: complete the purchase, post the result as a
      "Done" mission card with "Verified by Beltic" footer

User revokes an agent OR re-verifies identity:
   → POST /v1/credentials/{id}/revoke
   → status flips, webhook fires, agent can no longer transact
```

## Components

### Ruby Beltic client (`lib/houston/beltic/`)

Houston is Ruby/Rails. Beltic's published SDK is TypeScript-only. We wrap their REST API via Faraday (already in Houston's Gemfile).

- `Houston::Beltic` — module entry, configuration, ENV plumbing
- `Houston::Beltic::Client` — Faraday HTTP wrapper, retries, `X-Api-Key` auth
- `Houston::Beltic::Issuer` — typed `issue_business`, `issue_user`, `issue_agent_authorization` methods that build the right `subject`/`claims` shape per Beltic's schema
- `Houston::Beltic::Verifier` — local JWT-VC verification using cached JWKS from `/.well-known/jwks.json`; falls back to server-side `POST /v1/credentials/:id/verify` when an audit trail is needed
- `Houston::Beltic::WebhookVerifier` — HMAC-SHA256 (RFC 7797 detached JWT) verification of incoming webhook events
- `Houston::Beltic::Errors` — typed exception hierarchy mirroring Beltic's error codes (`self_attestation_incomplete`, `kyb_required`, etc.)

### Settings nav placement (Houston desktop app v0.4.12)

Houston's Settings is a 3-pane layout: main sidebar → Settings sub-nav (Account, Workspace, Workspace context, User context, AI provider, Connect phone, Report bug) → content. Each content page stacks form sections vertically (heading, helper text, control), ending in a red Danger zone.

The Beltic integration adds **two new Settings sub-nav items** following the existing pattern:

- **Identity** — verified credential status, trust level, strengthening options (upload ID, add evidence, connect external accounts), revoke. Sections: "Your identity" / "Strengthen your identity" / "Recent activity" / "Danger zone (revoke credential)".
- **Agents** — list of authorized agents, per-agent limits, audit log, revoke. Sections: "Authorized agents" / "Default limits for new agents" / "Recent purchase verifications" / "Danger zone (revoke all)".

Why two items and not one combined "Identity & Agents": each Settings item in the existing app maps to a single concern. Splitting matches that convention and gives clean entry points for deep-linking from the agent-authorization modal ("revoke" → Settings/Agents) and from the verification card on a mission ("manage identity" → Settings/Identity).

(Note: an earlier Figma mockup combined these into one card-heavy page. After this PR scaffolds the controllers, the mockup will be redone in the actual 3-pane Settings layout.)

### Rails surfaces (`app/`)

- `VerifiableCredential` model — one row per credential issued for a Houston user/agent. Stores `credential_id`, `credential_type`, `subject_id`, `status`, `expires_at`, `signed_payload` (encrypted at rest), `claims` (JSONB), `evidence_refs` (JSONB), `delegated_by_credential_id` (FK to another VC), timestamps.
- `IdentityVerificationsController` — `new`/`create` for the self-attestation modal flow. On success, enqueues `Beltic::IssueCredentialJob`.
- `AgentAuthorizationsController` — `new`/`create`/`destroy` for the per-agent consent flow. `destroy` calls revoke.
- `IdentityStrengthenController` — `new`/`create` for **credential strengthening**: upload an ID document → re-issue user credential at a higher `trust_level`; upload professional credentials → issue stacked outcome credentials linked via `parent_user_id`. See "Credential strengthening" below.
- `Webhooks::BelticController` — `create` endpoint receiving `credential.revoked`, `credential.suspended`, `credential.issued` callbacks. Verifies HMAC, updates the VC row, fires `Houston.observer.fire("beltic.credential_status_changed", ...)`.
- `Beltic::IssueCredentialJob` — async wrapper around `Issuer#issue_*`. Retries with exponential backoff. On `self_attestation_incomplete` (422), it does NOT retry — surface the error to the user.

### Config

- `config/initializers/beltic.rb` — exposes `Houston.config.beltic { |b| b.api_key = ...; b.base_url = ...; b.org_credential_id = ...; b.webhook_secret = ... }`
- ENV vars: `BELTIC_API_KEY`, `BELTIC_BASE_URL` (default `https://api.beltic.com/v1`), `BELTIC_WEBHOOK_SECRET`, `BELTIC_ORG_CREDENTIAL_ID`
- Encrypted Rails credentials preferred over plain ENV in production (use `Rails.application.credentials.beltic`)

### Data model additions

```
verifiable_credentials
  id                          bigint pk
  credential_id               string  uniq  not null  # Beltic-side ID, e.g. cred_a8f3...
  credential_type             string  not null        # business | user | agent_authorization
  subject_type                string  not null        # User | Agent | Organization
  subject_id                  bigint  not null
  status                      string  not null        # active | suspended | revoked | expired
  signed_payload              text    encrypted       # JWT-VC
  claims                      jsonb   not null
  evidence_refs               jsonb   default '[]'
  delegated_by_credential_id  bigint  fk (self)       # for agent VCs, points to user VC
  issued_at                   timestamp
  expires_at                  timestamp
  revoked_at                  timestamp
  raw_response                jsonb                   # full Beltic API response, for audit
  created_at, updated_at

  indexes:
    (subject_type, subject_id)
    (credential_id) unique
    (status)
    (expires_at) where status = 'active'

agents (new table — Houston doesn't have one yet)
  id                          bigint pk
  user_id                     bigint fk users
  name                        string
  did                         string  uniq            # did:jwk:... (subject DID)
  status                      string                  # active | paused | revoked
  spend_limit_amount_cents    integer
  spend_limit_currency        string                  # ISO-4217
  spend_limit_period          string                  # per_transaction | daily | weekly | monthly | lifetime
  per_transaction_max_cents   integer
  authorized_currencies       jsonb                   # ["USD","BRL"]
  max_idle_duration_iso8601   string                  # PT4H
  confirmation_threshold_cents integer                # cents above which to ask user; null = always or never (see flag)
  confirmation_mode           string                  # always | threshold | never
  created_at, updated_at

users (additive columns only — no breaking changes)
  beltic_user_credential_id   bigint fk verifiable_credentials   # current active user VC
  beltic_trust_level          string                              # cached: self_attested|liveness_verified|idv_verified|enterprise_verified
```

## Credential strengthening (Settings → Identity)

After initial issuance, the user's credential is at `trust_level: self_attested`. To raise it, the user can:

1. **Upload a government ID** — triggers re-issuance of the user credential with `id_document_type`/`id_document_country` set and `trust_level: idv_verified`. The old credential is revoked atomically (Beltic guarantees status-list update before the new one returns).
2. **Add supporting evidence** — receipts, address proofs, employer letters. These attach to the credential's `evidence_refs` array (each is a hash of the document stored encrypted; Beltic doesn't hold the doc, just the hash). Re-issues at the same trust level with a longer `evidence_refs` list.
3. **Stack outcome attestations** — for things that aren't part of the base ID schema (LinkedIn profile, GitHub identity, professional license). These mint a separate `outcome_attestation` credential with `parent_user_id` pointing back to the user's main credential. Surfaced together in Settings as a list of attached attestations.

UI shape: Settings → Identity & Agents page gains a new section "Strengthen your identity" with the user's current trust level, a list of attached evidence/attestations, and "Upload ID", "Add evidence", "Connect external account" actions. Figma mockup to follow.

API surface:
- `POST /v1/credentials` again (revokes old, issues new) for ID upload / evidence
- `POST /v1/credentials` with `credential_type: outcome_attestation, subject.parent_user_id: <user_cred_id>` for stacked attestations
- `POST /v1/credentials/{old_id}/revoke` is implicit in the re-issuance flow

## Routes (to add to `config/routes.rb`)

```ruby
# Identity verification
resource :identity_verification, only: [:new, :create]
resource :identity_strengthening, only: [:new, :create]

# Agent authorization
resources :agents do
  resource :authorization, only: [:new, :create, :destroy], controller: "agent_authorizations"
end

# Webhooks
namespace :webhooks do
  resource :beltic, only: [:create]
end
```

## Security considerations

- `signed_payload` stored encrypted-at-rest (`attr_encrypted` or Rails 7+ encrypted attributes — currently 6.0, will need `attr_encrypted` gem)
- Webhook endpoint verifies HMAC signature BEFORE deserializing JSON; reject mismatched signatures with 401
- API key in ENV/credentials only — never in code, never in logs (Faraday redactor on `X-Api-Key` header)
- Verifier caches JWKS with respect for `Cache-Control`; force-refresh on a key-id miss
- `delegated_by_subject_id` is REQUIRED by Beltic when an agent's permissions include `resource_type: "wallet"` (FinCEN AML) — Issuer validates this client-side too
- Rate limit the user-facing self-attestation endpoint (prevent attestation spamming → cost)

## Phasing

| Phase | Scope | Status |
|---|---|---|
| 0 | Ruby client + business credential bootstrap + Settings → Identity card | this PR |
| 1 | User self-attestation flow + verifiable_credentials table | this PR |
| 2 | Agents table + agent_authorization issuance + Settings → Agents list | this PR |
| 3 | Purchase-time verifier hook in Houston's mission/purchase pipeline | follow-up |
| 4 | Credential strengthening (Settings → Strengthen your identity) | follow-up |
| 5 | Webhooks → credential status sync | follow-up |
| 6 | Recovery flows (lost device, agent compromise, key rotation) | later |

## What's in this PR (initial scaffold)

- This design doc
- `lib/houston/beltic/` skeleton (client, issuer, verifier, webhook_verifier, errors)
- `config/initializers/beltic.rb` with config block
- `app/models/verifiable_credential.rb` + migration
- `app/models/agent.rb` + migration
- Controller stubs: `identity_verifications`, `agent_authorizations`, `webhooks/beltic`
- Job stub: `beltic/issue_credential_job`
- `.env.example` documenting required ENV vars

None of these files are wired into routes yet — `config/routes.rb` is unchanged. Wiring happens in follow-up commits on the same branch after the scaffold is reviewed.

## References

- Beltic platform repo: `/Users/sophiacastor/Documents/Work/Beltic/platform`
- Beltic credentials API: `apps/api/credentials/` in the Beltic platform repo
- Beltic schemas: `packages/schemas/src/credentials/`
- Self-attestation integration guide: `docs/credentials-self-attestation-integration-guide.md` (in Beltic platform)
- Figma design surfaces: https://www.figma.com/design/m9EpQoMdechc1XfFnCqA9I (page "v2 — Houston Desktop")
