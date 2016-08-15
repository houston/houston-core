class CreateTestResults < ActiveRecord::Migration
  def up
    execute "CREATE TYPE test_result_status AS ENUM ('fail', 'skip', 'pass')"

    create_table :test_results do |t|
      t.integer :test_run_id, null: false
      t.integer :test_id, null: false
      t.column :status, :test_result_status, null: false
      t.boolean :regression, null: true, default: nil
      t.float :duration
      t.integer :error_id

      t.index :test_run_id
      t.index :test_id
    end

    execute "ALTER TABLE test_results ADD CONSTRAINT test_results_unique_constraint UNIQUE (test_run_id, test_id)"

    errors_map = Hash[TestError.pluck(:sha, :id)]

    test_runs = TestRun.completed
    project_ids = test_runs.reorder(nil).pluck "DISTINCT project_id"
    pbar = ProgressBar.new("test runs", test_runs.count)
    project_ids.each do |project_id|
      tests_map = Hash[Test.where(project_id: project_id)
        .pluck(:suite, :name, :id)
        .map { |suite, name, id| [[suite, name], id] }]

      test_runs.where(project_id: project_id).pluck_in_batches(:id, :tests, of: 50) do |id, tests|
        test_results = Array(tests).map do |test_attributes|
          suite = test_attributes.fetch :suite
          name = test_attributes.fetch :name

          status = test_attributes.fetch :status
          status = :fail if status == :error or status == :regression

          error_message = test_attributes[:error_message]
          error_backtrace = (test_attributes[:error_backtrace] || []).join("\n")
          output = [error_message, error_backtrace].reject(&:blank?).join("\n\n")
          if output.blank?
            error_id = nil
          else
            sha = Digest::SHA1.hexdigest(output)
            error_id = errors_map[sha]
            unless error_id
             error = TestError.create!(output: output)
             error_id = errors_map[error.sha] = error.id
            end
          end

          { test_run_id: id,
            test_id: tests_map[[suite, name]],
            error_id: output.blank? ? nil : output,
            status: status,
            error_id: error_id,
            duration: test_attributes.fetch(:duration, nil) }
        end.uniq { |attributes| attributes[:test_id] }

        TestResult.insert_many(test_results)
        pbar.inc
      end # pluck_in_batches
    end # project_ids.each
    pbar.finish
  end

  def down
    drop_table :test_results
    execute "DROP TYPE IF EXISTS test_result_status"
  end
end

# 8216 test_runs in
