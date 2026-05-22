class VerifiableCredential < ActiveRecord::Base
  TYPES = %w[business user agent_authorization outcome_attestation].freeze
  STATUSES = %w[active suspended revoked expired].freeze

  # signed_payload is the raw JWT-VC. Encrypted at rest because anyone holding it
  # can present it as proof of identity until revoked. Requires LOCKBOX_MASTER_KEY
  # (generate with: bundle exec rake "lockbox:generate_key").
  has_encrypted :signed_payload if respond_to?(:has_encrypted)

  belongs_to :subject,                polymorphic: true
  belongs_to :delegated_by_credential, class_name: "VerifiableCredential", optional: true

  has_many :delegated_credentials,
           class_name:  "VerifiableCredential",
           foreign_key: :delegated_by_credential_id

  validates :credential_id,   presence: true, uniqueness: true
  validates :credential_type, inclusion: { in: TYPES }
  validates :status,          inclusion: { in: STATUSES }

  scope :active,   -> { where(status: "active") }
  scope :expired,  -> { where("expires_at < ?", Time.current) }
  scope :for_type, ->(type) { where(credential_type: type) }

  def active?
    status == "active" && (expires_at.nil? || expires_at.future?)
  end

  def revoked?
    status == "revoked"
  end

  # Truncated credential ID for UI display ("cred_a8f3...d92b1c").
  def short_id
    return credential_id if credential_id.length <= 18
    "#{credential_id[0, 9]}…#{credential_id[-6, 6]}"
  end
end
