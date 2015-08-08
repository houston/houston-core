class CreateTests < ActiveRecord::Migration
  def up
    create_table :tests do |t|
      t.integer :project_id, null: false
      t.string :suite, null: false
      t.text :name, null: false

      t.index :project_id
    end
    execute "ALTER TABLE tests ADD CONSTRAINT tests_unique_constraint UNIQUE (project_id, suite, name)"

    test_runs = TestRun.completed
    project_ids = test_runs.reorder(nil).pluck "DISTINCT project_id"
    pbar = ProgressBar.new("test runs", test_runs.count)
    project_ids.each do |project_id|
      tests = Set.new
      test_runs.where(project_id: project_id).pluck_in_batches(:tests) do |results|
        Array(results).each do |result|
          tests.add(project_id: project_id, suite: result[:suite], name: result[:name])
        end
        pbar.inc
      end
      Test.insert_many(tests.to_a)
    end
    pbar.finish
  end

  def down
    drop_table :tests
  end
end

# 8216 test_runs in 9 minutes, 25 seconds
