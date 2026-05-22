class CreateAgents < ActiveRecord::Migration[6.0]
  def change
    create_table :agents do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,                       null: false
      t.string  :did,                        null: false
      t.string  :status,                     null: false, default: "active"
      t.integer :spend_limit_amount_cents
      t.string  :spend_limit_currency
      t.string  :spend_limit_period
      t.integer :per_transaction_max_cents
      t.jsonb   :authorized_currencies,      null: false, default: []
      t.string  :max_idle_duration_iso8601
      t.integer :confirmation_threshold_cents
      t.string  :confirmation_mode,          null: false, default: "threshold"
      t.timestamps
    end

    add_index :agents, :did, unique: true
    add_index :agents, [:user_id, :status]
  end
end
