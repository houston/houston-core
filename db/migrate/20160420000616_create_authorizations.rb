class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.string :name, null: false
      t.integer :provider_id
      t.string :scope
      t.string :access_token, length: 1024
      t.string :refresh_token
      t.string :secret
      t.integer :expires_in
      t.timestamp :expires_at

      t.timestamps
    end
  end
end
