class CreateErrors2 < ActiveRecord::Migration
  def change
    create_table :errors do |t|
      t.string :sha, null: false
      t.text :message, null: false
      t.text :backtrace, null: false
      t.timestamps

      t.index :sha, unique: true
    end
  end
end
