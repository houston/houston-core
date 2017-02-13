class ChangeProvidersFromModelsToExtensions < ActiveRecord::Migration[5.0]
  def up
    drop_table :oauth_providers
    execute "DELETE FROM authorizations"

    remove_column :authorizations, :provider_id
    add_column :authorizations, :provider_name, :string, null: false
    add_reference :authorizations, :user, null: false, foreign_key: true
  end

  def down
    add_column :authorizations, :provider_id, :integer
    remove_column :authorizations, :provider
    remove_reference :authorizations, :user

    create_table :oauth_providers do |t|
      t.string :name, null: false
      t.string :site, null: false
      t.string :authorize_path, null: false
      t.string :token_path, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false

      t.timestamps
    end
  end
end
