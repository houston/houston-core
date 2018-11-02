class CreateApiTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :api_tokens do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.string :value, null: false

      t.index :value
    end
  end
end
