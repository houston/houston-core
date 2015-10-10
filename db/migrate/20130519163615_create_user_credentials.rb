class CreateUserCredentials < ActiveRecord::Migration
  def up
    create_table :user_credentials do |t|
      t.references :user
      t.string :service
      t.string :login
      t.binary :password
      t.binary :password_key
      t.binary :password_iv

      t.timestamps
    end
  end

  def down
    drop_table :user_credentials
  end
end
