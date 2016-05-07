class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name, null: false
      t.datetime :started_at, null: false

      t.datetime :finished_at
      t.boolean :succeeded
      t.integer :error_id

      t.index :name
    end
  end
end
