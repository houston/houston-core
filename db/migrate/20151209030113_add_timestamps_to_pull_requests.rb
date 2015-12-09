class AddTimestampsToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :created_at, :timestamp
    add_column :pull_requests, :updated_at, :timestamp
  end
end
