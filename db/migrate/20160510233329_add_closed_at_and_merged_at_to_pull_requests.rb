class AddClosedAtAndMergedAtToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :closed_at, :datetime
    add_column :pull_requests, :merged_at, :datetime
    add_index :pull_requests, :closed_at
  end
end
