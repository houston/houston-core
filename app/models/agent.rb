class Agent < ActiveRecord::Base
  STATUSES = %w[active paused revoked].freeze
  CONFIRMATION_MODES = %w[always threshold never].freeze
  SPEND_PERIODS = %w[per_transaction daily weekly monthly lifetime].freeze

  belongs_to :user
  has_many :verifiable_credentials, as: :subject, dependent: :destroy

  validates :name,              presence: true
  validates :did,               presence: true, uniqueness: true,
                                format: { with: /\Adid:jwk:/, message: "must be a did:jwk identifier" }
  validates :status,            inclusion: { in: STATUSES }
  validates :confirmation_mode, inclusion: { in: CONFIRMATION_MODES }
  validates :spend_limit_period, inclusion: { in: SPEND_PERIODS, allow_nil: true }

  scope :active, -> { where(status: "active") }

  # The current authorization credential (most recent active agent_authorization).
  def authorization_credential
    verifiable_credentials.active.for_type("agent_authorization").order(issued_at: :desc).first
  end

  def authorized?
    authorization_credential.present?
  end
end
