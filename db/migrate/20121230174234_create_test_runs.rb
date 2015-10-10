class CreateTestRuns < ActiveRecord::Migration
  def change
    create_table :test_runs do |t|
      t.integer :project_id, :null => false
      t.string :commit, :null => false

      t.datetime :completed_at
      t.string :results_url
      t.string :result
      t.integer :duration
      t.integer :fail_count
      t.integer :pass_count
      t.integer :skip_count
      t.hstore :details

      t.timestamps
    end

    add_index :test_runs, :project_id
    add_index :test_runs, :commit, :unique => true
  end
end
