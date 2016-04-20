class CreateOauthProviders < ActiveRecord::Migration
  def change
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
