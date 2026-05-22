class AddBelticFieldsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :beltic_user_credential,
                  foreign_key: { to_table: :verifiable_credentials },
                  null: true
    add_column :users, :beltic_trust_level, :string
    add_index  :users, :beltic_trust_level
  end
end
