class AddAgentEmailToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :agent_email, :string, :null => true
  end
end
