class CreateVerifiableCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :verifiable_credentials do |t|
      t.string  :credential_id,              null: false
      t.string  :credential_type,            null: false
      t.string  :subject_type,               null: false
      t.bigint  :subject_id,                 null: false
      t.string  :status,                     null: false, default: "active"
      t.text    :signed_payload_ciphertext
      t.jsonb   :claims,                     null: false, default: {}
      t.jsonb   :evidence_refs,              null: false, default: []
      t.bigint  :delegated_by_credential_id
      t.datetime :issued_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.jsonb   :raw_response,               null: false, default: {}
      t.timestamps
    end

    add_index :verifiable_credentials, :credential_id, unique: true
    add_index :verifiable_credentials, [:subject_type, :subject_id]
    add_index :verifiable_credentials, :status
    add_index :verifiable_credentials, :expires_at,
              where: "status = 'active'",
              name:  "idx_active_vcs_by_expiry"
    add_foreign_key :verifiable_credentials,
                    :verifiable_credentials,
                    column: :delegated_by_credential_id
  end
end
